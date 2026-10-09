import 'package:flutter/cupertino.dart';

import '../services/locale_controller.dart';
import '../services/root_tab_navigation.dart';

import 'adhkar_screen.dart';
import 'bookmarks_screen.dart';
import 'calendar_screen.dart';
import 'fasting_screen.dart';
import 'qibla_screen.dart';
import 'reading_history_screen.dart';
import 'settings_screen.dart';
import 'tasbih_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(LocaleController.isArabic ? 'المزيد' : 'More')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 100),
          children: [
            CupertinoListSection.insetGrouped(
              header: Text(LocaleController.isArabic ? 'مساحتك' : 'YOUR SPACE'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.bookmark),
                  title: Text(LocaleController.isArabic ? 'العلامات المرجعية' : 'Bookmarks'),
                  subtitle: Text(LocaleController.isArabic ? 'الآيات المحفوظة' : 'Saved Quran ayahs'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const BookmarksScreen()),
                  ),
                ),

                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.clock),
                  title: Text(LocaleController.isArabic ? 'سجل القراءة' : 'Reading history'),
                  subtitle: Text(LocaleController.isArabic ? 'آخر مواضع القرآن التي قرأتها' : 'Recently opened Quran passages'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const ReadingHistoryScreen()),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.circle_grid_3x3),
                  title: Text(LocaleController.isArabic ? 'التسبيح' : 'Tasbih'),
                  subtitle: Text(LocaleController.isArabic ? 'عداد ذكر يعمل دون إنترنت' : 'Offline dhikr counter'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const TasbihScreen()),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.bookmark),
                  title: Text(LocaleController.isArabic ? 'أذكار يومية' : 'Daily Adhkar'),
                  subtitle: Text(LocaleController.isArabic ? 'مجموعة أذكار دون إنترنت' : 'Offline remembrance collection'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const AdhkarScreen()),
                  ),
                ),

                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.moon_fill),
                  title: Text(LocaleController.isArabic ? 'الصيام' : 'Fasting'),
                  subtitle: Text(LocaleController.isArabic ? 'رمضان ومواقيت الصيام دون إنترنت' : 'Offline Ramadan and fasting times'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const FastingScreen()),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.calendar),
                  title: Text(LocaleController.isArabic ? 'التقويم' : 'Calendar'),
                  subtitle: Text(LocaleController.isArabic ? 'التاريخ الميلادي والهجري التقريبي' : 'Gregorian and approximate Hijri date'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const CalendarScreen()),
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: Text(LocaleController.isArabic ? 'الأدوات' : 'TOOLS'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.compass),
                  title: Text(LocaleController.isArabic ? 'القبلة' : 'Qibla'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    RootTabNavigation.maybeOf(context)?.selectTab(3);
                  },
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.gear),
                  title: Text(LocaleController.isArabic ? 'الإعدادات' : 'Settings'),
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
                  title: Text(LocaleController.isArabic ? 'يعمل دون اتصال' : 'Offline-first'),
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
