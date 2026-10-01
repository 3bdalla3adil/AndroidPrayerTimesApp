import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'calendar_screen.dart';
import 'bookmarks_screen.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storage = StorageService();
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 110),
      children: [
        Text('YOUR SPACE', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.6, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
        const SizedBox(height: 7),
        Text('More', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        Text('Personal settings and saved reading.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 28),
        Text('Your location', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Card(child: ListTile(
          leading: CircleAvatar(backgroundColor: theme.colorScheme.secondaryContainer, child: Icon(Icons.location_on_outlined, color: theme.colorScheme.primary)),
          title: FutureBuilder<(double?, double?, String?)>(
            future: storage.loadLocation(),
            builder: (context, snapshot) => Text(snapshot.data?.$3 ?? 'Not set'),
          ),
          subtitle: const Text('Used locally for prayer times and Qibla.'),
        )),
        const SizedBox(height: 24),
        Text('Quran', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _MenuRow(icon: Icons.bookmark_outline, title: 'Saved bookmarks', detail: 'Open the ayahs you saved while reading', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksScreen()))),
        const SizedBox(height: 24),
        Text('Explore', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _MenuRow(icon: Icons.calendar_month_outlined, title: 'Prayer calendar', detail: 'View the month and daily timings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()))),
        _MenuRow(icon: Icons.explore_outlined, title: 'Qibla', detail: 'Find the direction of prayer', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen()))),
        _MenuRow(icon: Icons.tune_outlined, title: 'Settings', detail: 'Prayer reminders and Quran preferences', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        const SizedBox(height: 24),
        Card(
          color: theme.colorScheme.secondaryContainer,
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('About this Quran text', style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Arabic text: Tanzil Project Uthmani text. Copyright © 2007–2021 Tanzil Project; Creative Commons Attribution 3.0.'),
              SizedBox(height: 12),
              Text('Quran Majeed-style offline Quran and prayer companion — rebuilt in Flutter for Android and iOS.'),
            ]),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.title, required this.detail, required this.onTap});
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: theme.colorScheme.secondaryContainer, child: Icon(icon, color: theme.colorScheme.primary)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(detail),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
