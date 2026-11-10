import 'dart:convert';

import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

enum WirdUnit { juz, hizb, ayah }

class WirdPosition {
  const WirdPosition(this.surah, this.ayah);
  final int surah;
  final int ayah;
  Map<String, int> toJson() => {'surah': surah, 'ayah': ayah};
  factory WirdPosition.fromJson(Map<String, dynamic> json) =>
      WirdPosition((json['surah'] as num).toInt(), (json['ayah'] as num).toInt());
}

class DailyWirdPlan {
  const DailyWirdPlan({
    required this.unit,
    required this.amount,
    required this.start,
    required this.end,
    required this.progress,
    required this.completed,
    required this.dateKey,
  });
  final WirdUnit unit;
  final int amount;
  final WirdPosition start;
  final WirdPosition end;
  final WirdPosition progress;
  final bool completed;
  final String dateKey;

  int get totalAyahs => _global(end) - _global(start) + 1;
  int get completedAyahs =>
      (_global(progress) - _global(start) + 1).clamp(0, totalAyahs).toInt();
  double get fraction => totalAyahs == 0 ? 0 : completedAyahs / totalAyahs;

  static int _global(WirdPosition p) {
    var result = p.ayah;
    for (var s = 1; s < p.surah; s++) {
      result += quran.getVerseCount(s);
    }
    return result;
  }
}

class DailyWirdService {
  DailyWirdService([SharedPreferencesAsync? preferences])
      : _prefs = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _prefs;

  static const _unitKey = 'daily_wird_unit';
  static const _amountKey = 'daily_wird_amount';
  static const _nextSurahKey = 'daily_wird_next_surah';
  static const _nextAyahKey = 'daily_wird_next_ayah';
  static const _completedDateKey = 'daily_wird_completed_date';
  static const _progressKey = 'daily_wird_progress';
  static const _historyKey = 'daily_wird_history';

  // First ayah of each of the 60 standard Hizbs (Hafs/Madinah Mushaf).
  static const List<List<int>> _hizbStarts = [[1,1],[2,75],[2,142],[2,203],[2,253],[3,15],[3,93],[3,171],[4,24],[4,88],[4,148],[5,27],[5,82],[6,36],[6,111],[7,1],[7,88],[7,171],[8,41],[9,34],[9,93],[10,26],[11,6],[11,84],[12,53],[13,19],[15,1],[16,51],[17,1],[17,99],[18,75],[19,96],[21,1],[22,1],[23,1],[24,21],[25,21],[26,111],[27,82],[28,76],[29,64],[31,22],[33,31],[34,24],[36,28],[37,145],[39,32],[40,41],[41,47],[43,24],[46,1],[48,18],[51,31],[55,1],[57,16],[60,1],[65,1],[68,52],[75,1],[82,1]];

  Future<WirdUnit> loadUnit() async {
    final value = await _prefs.getString(_unitKey);
    for (final unit in WirdUnit.values) {
      if (unit.name == value) return unit;
    }
    return WirdUnit.juz;
  }

  Future<int> loadAmount() async =>
      (await _prefs.getInt(_amountKey) ?? 1).clamp(1, 6236).toInt();

  Future<void> saveSettings(WirdUnit unit, int amount) async {
    await _prefs.setString(_unitKey, unit.name);
    await _prefs.setInt(_amountKey, amount.clamp(1, 6236).toInt());
  }

  Future<DailyWirdPlan> loadToday() async {
    final date = _dateKey(DateTime.now());
    final unit = await loadUnit();
    final amount = await loadAmount();
    final completedDate = await _prefs.getString(_completedDateKey);
    final savedDate = await _prefs.getString('daily_wird_plan_date');
    final savedStart = await _prefs.getString('daily_wird_plan_start');
    WirdPosition start;
    if (savedDate == date && savedStart != null) {
      start = WirdPosition.fromJson(
        Map<String, dynamic>.from(jsonDecode(savedStart) as Map),
      );
    } else {
      final surah = (await _prefs.getInt(_nextSurahKey) ?? 1).clamp(1, 114).toInt();
      final ayah = (await _prefs.getInt(_nextAyahKey) ?? 1)
          .clamp(1, quran.getVerseCount(surah)).toInt();
      start = WirdPosition(surah, ayah);
      await _prefs.setString('daily_wird_plan_date', date);
      await _prefs.setString('daily_wird_plan_start', jsonEncode(start.toJson()));
      await _prefs.setInt(_progressKey + '_surah', start.surah);
      await _prefs.setInt(_progressKey + '_ayah', start.ayah);
    }
    final end = _calculateEnd(start, unit, amount);
    final progressSurah = (await _prefs.getInt(_progressKey + '_surah') ?? start.surah)
        .clamp(1, 114).toInt();
    final progressAyah = (await _prefs.getInt(_progressKey + '_ayah') ?? start.ayah)
        .clamp(1, quran.getVerseCount(progressSurah)).toInt();
    return DailyWirdPlan(
      unit: unit,
      amount: amount,
      start: start,
      end: end,
      progress: WirdPosition(progressSurah, progressAyah),
      completed: completedDate == date,
      dateKey: date,
    );
  }

  Future<void> recordReadThrough(int surah, int ayah) async {
    if (surah < 1 || surah > 114 || ayah < 1 || ayah > quran.getVerseCount(surah)) return;
    final plan = await loadToday();
    if (plan.completed) return;
    final current = _global(WirdPosition(surah, ayah));
    final start = _global(plan.start);
    final end = _global(plan.end);
    if (current < start) return;
    final effective = current.clamp(start, end).toInt();
    final oldSurah = (await _prefs.getInt(_progressKey + '_surah') ?? plan.start.surah)
        .clamp(1, 114).toInt();
    final oldAyah = (await _prefs.getInt(_progressKey + '_ayah') ?? plan.start.ayah)
        .clamp(1, quran.getVerseCount(oldSurah)).toInt();
    if (effective <= _global(WirdPosition(oldSurah, oldAyah))) return;
    final position = _fromGlobal(effective);
    await _prefs.setInt(_progressKey + '_surah', position.surah);
    await _prefs.setInt(_progressKey + '_ayah', position.ayah);
  }

  Future<void> confirmCompletion() async {
    final plan = await loadToday();
    if (plan.completed) return;
    final next = _global(plan.end) >= quran.totalVerseCount
        ? const WirdPosition(1, 1)
        : _fromGlobal(_global(plan.end) + 1);
    await _prefs.setString(_completedDateKey, plan.dateKey);
    await _prefs.setInt(_nextSurahKey, next.surah);
    await _prefs.setInt(_nextAyahKey, next.ayah);
    await _prefs.setInt(_progressKey + '_surah', plan.end.surah);
    await _prefs.setInt(_progressKey + '_ayah', plan.end.ayah);
    final history = await _prefs.getStringList(_historyKey) ?? <String>[];
    if (!history.contains(plan.dateKey)) {
      history.add(plan.dateKey);
      await _prefs.setStringList(_historyKey, history);
    }
  }

  Future<List<String>> loadCompletionHistory() async =>
      await _prefs.getStringList(_historyKey) ?? <String>[];

  WirdPosition _calculateEnd(WirdPosition start, WirdUnit unit, int amount) {
    if (unit == WirdUnit.ayah) {
      return _fromGlobal((_global(start) + amount - 1)
          .clamp(1, quran.totalVerseCount).toInt());
    }
    if (unit == WirdUnit.juz) {
      final firstJuz = quran.getJuzNumber(start.surah, start.ayah);
      final lastJuz = (firstJuz + amount - 1).clamp(1, 30).toInt();
      final mapping = quran.getSurahAndVersesFromJuz(lastJuz);
      final surahs = mapping.keys.toList()..sort();
      final lastSurah = surahs.last;
      return WirdPosition(lastSurah, mapping[lastSurah]!.last);
    }
    var index = 0;
    final startGlobal = _global(start);
    for (var i = 0; i < _hizbStarts.length; i++) {
      if (_global(WirdPosition(_hizbStarts[i][0], _hizbStarts[i][1])) <= startGlobal) {
        index = i;
      } else {
        break;
      }
    }
    final nextIndex = index + amount;
    if (nextIndex >= _hizbStarts.length) return const WirdPosition(114, 6);
    final next = WirdPosition(_hizbStarts[nextIndex][0], _hizbStarts[nextIndex][1]);
    return _fromGlobal(_global(next) - 1);
  }

  int _global(WirdPosition p) {
    var result = p.ayah;
    for (var s = 1; s < p.surah; s++) result += quran.getVerseCount(s);
    return result;
  }

  WirdPosition _fromGlobal(int value) {
    var remaining = value.clamp(1, quran.totalVerseCount).toInt();
    for (var surah = 1; surah <= 114; surah++) {
      final count = quran.getVerseCount(surah);
      if (remaining <= count) return WirdPosition(surah, remaining);
      remaining -= count;
    }
    return const WirdPosition(114, 6);
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
