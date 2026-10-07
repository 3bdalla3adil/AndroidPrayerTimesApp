import 'package:flutter/cupertino.dart';

import '../services/athan_reminder_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();
  late final AthanReminderService _athan;
  bool _reminders = false;
  bool _loading = true;
  int _scheduled = 0;
  int _method = 3;
  int _madhab = 0;
  Set<String> _enabledPrayers = StorageService.prayerNames.toSet();
  Map<String, int> _adjustments = {};
  int _preReminderMinutes = 0;
  String _athanSound = 'default';
  double _quranFontSize = 28;
  bool _quranTranslation = false;
  bool _quranDarkPage = false;
  int _tasbihTarget = 33;

  static const _methods = <int, String>{
    1: 'Karachi', 2: 'North America (ISNA)', 3: 'Muslim World League',
    4: 'Umm Al-Qura', 5: 'Egyptian', 7: 'Tehran', 8: 'Gulf Region',
    9: 'Kuwait', 10: 'Qatar', 11: 'Singapore', 12: 'France',
    13: 'Türkiye', 16: 'Dubai', 17: 'Singapore (alternate)',
    18: 'Tunisia', 20: 'Indonesia', 21: 'Morocco',
    23: 'Muslim World League (custom)',
  };

  @override void initState() {
    super.initState();
    _athan = AthanReminderService(PrayerService(_storage), _storage);
    _load();
  }

  Future<void> _load() async {
    final enabled = await _storage.loadAthanRemindersEnabled();
    final count = await NotificationService.pendingCount();
    final city = await _storage.loadPrayerCity();
    final savedMethod = await _storage.loadPrayerCalculationMethod();
    final madhab = await _storage.loadPrayerMadhab();
    final enabledPrayers = await _storage.loadEnabledPrayerNames();
    final adjustments = await _storage.loadPrayerTimeAdjustments();
    final preReminderMinutes = await _storage.loadPrePrayerReminderMinutes();
    final athanSound = await _storage.loadAthanSound();
    final quranFontSize = await _storage.loadQuranFontSize();
    final quranTranslation = await _storage.loadQuranShowTranslation();
    final quranDarkPage = await _storage.loadQuranDarkPage();
    final tasbih = await _storage.loadTasbih();
    if (!mounted) return;
    setState(() {
      _reminders = enabled;
      _scheduled = count;
      _method = savedMethod ?? city.$3 ?? 3;
      _madhab = madhab;
      _enabledPrayers = enabledPrayers;
      _adjustments = adjustments;
      _preReminderMinutes = preReminderMinutes;
      _athanSound = NotificationService.soundLabels.containsKey(athanSound) ? athanSound : 'default';
      _quranFontSize = quranFontSize.clamp(20, 38).toDouble();
      _quranTranslation = quranTranslation;
      _quranDarkPage = quranDarkPage;
      _tasbihTarget = tasbih.$2;
      _loading = false;
    });
  }


  Future<void> _refreshSchedules() async {
    if (!_reminders) return;
    try {
      await _athan.sync();
      final count = await NotificationService.pendingCount();
      if (mounted) setState(() => _scheduled = count);
    } catch (e) {
      if (mounted) await _showError('Reminder update failed', e);
    }
  }

  Future<void> _togglePrayer(String prayer, bool enabled) async {
    final next = {..._enabledPrayers};
    if (enabled) {
      next.add(prayer);
    } else {
      next.remove(prayer);
    }
    if (next.isEmpty) {
      await _showError('At least one prayer must remain enabled', null);
      return;
    }
    await _storage.saveEnabledPrayerNames(next);
    if (mounted) setState(() => _enabledPrayers = next);
    await _refreshSchedules();
  }

  Future<void> _chooseAdjustment(String prayer) async {
    final current = _adjustments[prayer] ?? 0;
    final selected = await showCupertinoModalPopup<int>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('$prayer time adjustment'),
        message: Text('Current: ${current >= 0 ? '+' : ''}$current minutes'),
        actions: [
          for (var value = -60; value <= 60; value += 5)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, value),
              child: Text('${value >= 0 ? '+' : ''}$value minutes'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (selected == null) return;
    final next = {..._adjustments};
    if (selected == 0) {
      next.remove(prayer);
    } else {
      next[prayer] = selected;
    }
    await _storage.savePrayerTimeAdjustments(next);
    if (mounted) setState(() => _adjustments = next);
    await _refreshSchedules();
  }

  Future<void> _chooseQuranFontSize() async {
    final selected = await showCupertinoModalPopup<double>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('حجم خط المصحف'),
        message: const Text('اختر حجمًا واضحًا للنص العربي العثماني.'),
        actions: [
          for (final value in const [20.0, 22.0, 24.0, 26.0, 28.0, 30.0, 32.0, 34.0, 36.0, 38.0])
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, value),
              child: Text(value.round().toString()),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
    if (selected == null) return;
    await _storage.saveQuranFontSize(selected);
    if (mounted) setState(() => _quranFontSize = selected);
  }

  Future<void> _chooseTasbihTarget() async {
    final controller = TextEditingController(text: _tasbihTarget.toString());
    final selected = await showCupertinoDialog<int>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('هدف التسبيح'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            placeholder: '33 أو 99 أو أي رقم حتى 10000',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value >= 1 && value <= 10000) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (selected == null) return;
    await _storage.saveTasbih(0, selected);
    if (mounted) setState(() => _tasbihTarget = selected);
  }

  Future<void> _chooseAthanSound() async {
    final selected = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Athan sound'),
        message: const Text('Choose the bundled Athan recording used at every prayer time.'),
        actions: [
          for (final entry in NotificationService.soundLabels.entries)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, entry.key),
              child: Text(entry.value),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (selected == null) return;
    await _storage.saveAthanSound(selected);
    if (mounted) setState(() => _athanSound = selected);
    await _refreshSchedules();
  }

  Future<void> _testAthan() async {
    try {
      await NotificationService.scheduleTestAthan(soundId: _athanSound);
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Athan test scheduled'),
          content: const Text('The Athan notification will trigger in about 5 seconds. Keep the device audio enabled.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      await _showError('Athan test failed', e);
    }
  }

  Future<void> _choosePreReminder() async {
    final selected = await showCupertinoModalPopup<int>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Pre-prayer reminder'),
        message: const Text('When enabled, the schedule uses 6 days so iOS stays within its 64-notification pending limit.'),
        actions: [
          for (final value in const [0, 5, 10, 15, 20, 30])
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, value),
              child: Text(value == 0 ? 'Off' : '$value minutes before'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (selected == null) return;
    await _storage.savePrePrayerReminderMinutes(selected);
    if (mounted) setState(() => _preReminderMinutes = selected);
    await _refreshSchedules();
  }

  Future<void> _showError(String title, Object? error) async {
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: error == null ? null : Text(error.toString()),
        actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(dialogContext))],
      ),
    );
  }

  Future<void> _chooseMethod() async {
    final selected = await showCupertinoModalPopup<int>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Calculation method'),
        actions: [
          for (final entry in _methods.entries)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, entry.key),
              child: Text(entry.value),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (selected == null) return;
    await _storage.savePrayerCalculationMethod(selected);
    if (mounted) setState(() => _method = selected);
    if (_reminders) {
      await _athan.sync();
      final count = await NotificationService.pendingCount();
      if (mounted) setState(() => _scheduled = count);
    }
  }

  Future<void> _chooseMadhab() async {
    final selected = await showCupertinoModalPopup<int>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Asr calculation'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 0),
            child: const Text('Shafi / Standard'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 1),
            child: const Text('Hanafi'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (selected == null) return;
    await _storage.savePrayerMadhab(selected);
    if (mounted) setState(() => _madhab = selected);
    if (_reminders) {
      await _athan.sync();
      final count = await NotificationService.pendingCount();
      if (mounted) setState(() => _scheduled = count);
    }
  }

  Future<void> _toggle(bool enabled) async {
    setState(() => _loading = true);
    try {
      if (enabled) {
        final count = await _athan.enable();
        if (mounted) setState(() { _reminders = true; _scheduled = count; _loading = false; });
      } else {
        await _athan.disable();
        if (mounted) setState(() { _reminders = false; _scheduled = 0; _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Athan setup failed'),
          content: Text(e.toString()),
          actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(dialogContext))],
        ),
      );
    }
  }

  @override Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
      child: SafeArea(
        child: _loading && !_reminders
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
                children: [
                  CupertinoListSection.insetGrouped(
                    header: const Text('PRAYER'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.bell_fill),
                        title: const Text('Athan reminders'),
                        subtitle: Text(_reminders
                            ? '$_scheduled notifications scheduled for the next 12 days.'
                            : 'Schedule local prayer notifications automatically.'),
                        trailing: CupertinoSwitch(value: _reminders, onChanged: _loading ? null : _toggle),
                      ),
                      for (final prayer in StorageService.prayerNames)
                        CupertinoListTile(
                          leading: Icon(_enabledPrayers.contains(prayer) ? CupertinoIcons.bell_fill : CupertinoIcons.bell_slash),
                          title: Text(prayer),
                          subtitle: Text(_adjustments[prayer] == null ? 'Athan enabled' : 'Adjustment: ${_adjustments[prayer]! >= 0 ? '+' : ''}${_adjustments[prayer]} min'),
                          trailing: CupertinoSwitch(
                            value: _enabledPrayers.contains(prayer),
                            onChanged: _loading ? null : (value) => _togglePrayer(prayer, value),
                          ),
                          onTap: _loading ? null : () => _chooseAdjustment(prayer),
                        ),

                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.alarm),
                        title: const Text('Pre-prayer reminder'),
                        subtitle: Text(_preReminderMinutes == 0 ? 'Off' : '$_preReminderMinutes minutes before each enabled prayer'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _loading ? null : _choosePreReminder,
                      ),
                      const CupertinoListTile(
                        leading: Icon(CupertinoIcons.info_circle),
                        title: Text('Prayer time adjustment'),
                        subtitle: Text('Long-press a prayer to adjust it by 5-minute steps.'),
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    header: const Text('PRAYER CALCULATION'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.time),
                        title: const Text('Calculation method'),
                        subtitle: Text(_methods[_method] ?? 'Muslim World League'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _loading ? null : _chooseMethod,
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.sun_max),
                        title: const Text('Asr method'),
                        subtitle: Text(_madhab == 1 ? 'Hanafi' : 'Shafi / Standard'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _loading ? null : _chooseMadhab,
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    header: const Text('ATHAN SOUND'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.music_note),
                        title: const Text('Athan sound'),
                        subtitle: Text(NotificationService.soundLabels[_athanSound] ?? 'Athan — Default'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _loading ? null : _chooseAthanSound,
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.play_circle_fill),
                        title: const Text('Test Athan sound'),
                        subtitle: const Text('Play the selected Athan through the same notification path used for prayer time.'),
                        onTap: _loading ? null : _testAthan,
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    header: const Text('QURAN / MUSHAF'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.textformat_size),
                        title: const Text('Arabic / Uthmani font size'),
                        subtitle: Text(_quranFontSize.round().toString() + ' pt'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _loading ? null : _chooseQuranFontSize,
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.globe),
                        title: const Text('English translation'),
                        subtitle: const Text('Show translation below each ayah'),
                        trailing: CupertinoSwitch(
                          value: _quranTranslation,
                          onChanged: _loading ? null : (value) async {
                            await _storage.saveQuranShowTranslation(value);
                            if (mounted) setState(() => _quranTranslation = value);
                          },
                        ),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.moon),
                        title: const Text('Dark Mushaf page'),
                        subtitle: const Text('Use a dark reading page'),
                        trailing: CupertinoSwitch(
                          value: _quranDarkPage,
                          onChanged: _loading ? null : (value) async {
                            await _storage.saveQuranDarkPage(value);
                            if (mounted) setState(() => _quranDarkPage = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    header: const Text('TASBIH'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.circle),
                        title: const Text('Tasbih target'),
                        subtitle: Text(_tasbihTarget.toString() + ' repetitions; alert appears when the goal is reached.'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _loading ? null : _chooseTasbihTarget,
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    header: const Text('PRIVACY & OFFLINE'),
                    children: const [
                      CupertinoListTile(
                        leading: Icon(CupertinoIcons.lock),
                        title: Text('No account'),
                        subtitle: Text('No login or cloud profile is required.'),
                      ),
                      CupertinoListTile(
                        leading: Icon(CupertinoIcons.wifi_slash),
                        title: Text('Offline Quran'),
                        subtitle: Text('The 604-page Mushaf is bundled in the app.'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
