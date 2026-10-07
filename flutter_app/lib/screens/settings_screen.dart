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

  @override void initState() {
    super.initState();
    _athan = AthanReminderService(PrayerService(_storage), _storage);
    _load();
  }

  Future<void> _load() async {
    final enabled = await _storage.loadAthanRemindersEnabled();
    final count = await NotificationService.pendingCount();
    if (!mounted) return;
    setState(() { _reminders = enabled; _scheduled = count; _loading = false; });
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
                            ? _scheduled.toString() + ' notifications scheduled for the next 12 days.'
                            : 'Schedule local prayer notifications automatically.'),
                        trailing: CupertinoSwitch(value: _reminders, onChanged: _loading ? null : _toggle),
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
