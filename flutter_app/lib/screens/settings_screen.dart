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
    if (!mounted) return;
    setState(() {
      _reminders = enabled;
      _scheduled = count;
      _method = savedMethod ?? city.$3 ?? 3;
      _madhab = madhab;
      _enabledPrayers = enabledPrayers;
      _adjustments = adjustments;
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
    if (enabled) next.add(prayer); else next.remove(prayer);
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
    if (selected == 0) next.remove(prayer); else next[prayer] = selected;
    await _storage.savePrayerTimeAdjustments(next);
    if (mounted) setState(() => _adjustments = next);
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
                          onLongPress: _loading ? null : () => _chooseAdjustment(prayer),
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
