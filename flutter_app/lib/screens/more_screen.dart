import 'package:flutter/cupertino.dart';

import '../services/app_routes.dart';
import '../services/locale_controller.dart';
import '../services/root_tab_navigation.dart';


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
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.bookmarks),
                ),

                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.clock),
                  title: Text(LocaleController.isArabic ? 'سجل القراءة' : 'Reading history'),
                  subtitle: Text(LocaleController.isArabic ? 'آخر مواضع القرآن التي قرأتها' : 'Recently opened Quran passages'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.readingHistory),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.circle_grid_3x3),
                  title: Text(LocaleController.isArabic ? 'التسبيح' : 'Tasbih'),
                  subtitle: Text(LocaleController.isArabic ? 'عداد ذكر يعمل دون إنترنت' : 'Offline dhikr counter'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.tasbih),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.bookmark),
                  title: Text(LocaleController.isArabic ? 'أذكار يومية' : 'Daily Adhkar'),
                  subtitle: Text(LocaleController.isArabic ? 'مجموعة أذكار دون إنترنت' : 'Offline remembrance collection'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.adhkar),
                ),

                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.moon_fill),
                  title: Text(LocaleController.isArabic ? 'الصيام' : 'Fasting'),
                  subtitle: Text(LocaleController.isArabic ? 'رمضان ومواقيت الصيام دون إنترنت' : 'Offline Ramadan and fasting times'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.fasting),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.calendar),
                  title: Text(LocaleController.isArabic ? 'التقويم' : 'Calendar'),
                  subtitle: Text(LocaleController.isArabic ? 'التاريخ الميلادي والهجري التقريبي' : 'Gregorian and approximate Hijri date'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.calendar),
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
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: Text(LocaleController.isArabic ? 'كلمة امتنان' : 'A NOTE OF GRATITUDE'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.gift, color: Color(0xFFC7A45A)),
                  title: Text(LocaleController.isArabic ? 'إهداء وتقدير' : 'A Gift of Gratitude'),
                  subtitle: Text(LocaleController.isArabic ? 'كلمات تقدير واحترام لوالد زوجتي العزيز' : 'A heartfelt dedication to my dear father-in-law'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.dedication),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
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
