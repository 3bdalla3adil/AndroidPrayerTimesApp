import 'package:flutter/cupertino.dart';

import 'bookmarks_screen.dart';
import 'calendar_screen.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';
import 'tasbih_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('More')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 100),
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('YOUR SPACE'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.bookmark),
                  title: const Text('Bookmarks'),
                  subtitle: const Text('Saved Quran ayahs'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const BookmarksScreen()),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.circle_grid_3x3),
                  title: const Text('Tasbih'),
                  subtitle: const Text('Offline dhikr counter'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const TasbihScreen()),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.calendar),
                  title: const Text('Calendar'),
                  subtitle: const Text('Gregorian and approximate Hijri date'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const CalendarScreen()),
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('TOOLS'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.compass),
                  title: const Text('Qibla'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const QiblaScreen()),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.gear),
                  title: const Text('Settings'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              children: [
                const CupertinoListTile(
                  leading: Icon(CupertinoIcons.lock_shield),
                  title: Text('Offline-first'),
                  subtitle: Text('Prayer calculations, Quran and Qibla work on-device.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
