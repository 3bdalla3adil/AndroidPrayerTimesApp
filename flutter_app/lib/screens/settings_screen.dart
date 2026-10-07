import 'package:flutter/cupertino.dart';

import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool reminders = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('PRAYER'),
              children: [
                CupertinoListTile(
                  title: const Text('Prayer reminders'),
                  subtitle: const Text('Schedule local notifications'),
                  trailing: CupertinoSwitch(
                    value: reminders,
                    onChanged: (value) async {
                      setState(() => reminders = value);
                      if (!value) await NotificationService.cancelAll();
                    },
                  ),
                ),
              ],
            ),
            const CupertinoListSection.insetGrouped(
              header: Text('PRIVACY'),
              children: [
                CupertinoListTile(
                  leading: Icon(CupertinoIcons.lock),
                  title: Text('No account'),
                  subtitle: Text('No login or cloud profile is required.'),
                ),
                CupertinoListTile(
                  leading: Icon(CupertinoIcons.wifi_slash),
                  title: Text('Offline Quran'),
                  subtitle: Text('Quran text is bundled with the application.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
