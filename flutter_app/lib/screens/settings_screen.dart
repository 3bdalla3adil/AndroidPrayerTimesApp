import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Prayer reminders'),
              subtitle: const Text('Manage scheduled prayer notifications from Home.'),
              value: reminders,
              onChanged: (value) async {
                setState(() => reminders = value);
                if (!value) await NotificationService.cancelAll();
              },
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quran source', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  Text(
                    'Arabic Quran text is provided offline through quran_data_dart and is based on Tanzil Project Uthmani Minimal text.',
                  ),
                  SizedBox(height: 14),
                  Text('Original project', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  Text(
                    'Salawat & Quran is a Flutter modernization of the original AndroidPrayerTimesApp.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
