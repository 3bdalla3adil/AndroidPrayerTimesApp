import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import '../core/adaptive_page_scaffold.dart';

import '../services/app_routes.dart';
import '../services/locale_controller.dart';
import '../theme/app_theme.dart';


class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      final arabic = LocaleController.isArabic;
      final groups = <(String, List<(IconData, String, String, String)>)>[
        (arabic ? 'مساحتك' : 'Your space', [
          (material.Icons.bookmark_outline, arabic ? 'العلامات المرجعية' : 'Bookmarks', arabic ? 'الآيات المحفوظة' : 'Saved Quran ayahs', AppRoutes.bookmarks),
          (material.Icons.menu_book_rounded, arabic ? 'الورد اليومي' : 'Daily Quran wird', arabic ? 'هدف قراءة متتابع وختمة منظمة' : 'A continuous daily Quran reading plan', AppRoutes.dailyWird),
          (material.Icons.school_outlined, arabic ? 'حفظ القرآن' : 'Quran memorization', arabic ? 'حفظ الآيات وتتبع المراجعة دون إنترنت' : 'Practice ayahs and track revision offline', AppRoutes.quranMemorization),
          (material.Icons.auto_awesome, arabic ? 'التسبيح' : 'Tasbih', arabic ? 'عداد ذكر يعمل دون إنترنت' : 'Offline dhikr counter', AppRoutes.tasbih),
          (material.Icons.favorite_outline, arabic ? 'أذكار يومية' : 'Daily Adhkar', arabic ? 'مجموعة أذكار دون إنترنت' : 'Offline remembrance collection', AppRoutes.adhkar),
          (material.Icons.nights_stay_outlined, arabic ? 'الصيام' : 'Fasting', arabic ? 'رمضان ومواقيت الصيام دون إنترنت' : 'Offline Ramadan and fasting times', AppRoutes.fasting),
          (material.Icons.calendar_month_outlined, arabic ? 'التقويم' : 'Calendar', arabic ? 'التاريخ الميلادي والهجري التقريبي' : 'Gregorian and approximate Hijri date', AppRoutes.calendar),
        ]),
        (arabic ? 'الأدوات' : 'Tools', [
          (material.Icons.explore_outlined, arabic ? 'القبلة' : 'Qibla', arabic ? 'اتجاه مكة' : 'Direction to Makkah', AppRoutes.qibla),
          (material.Icons.schedule_outlined, arabic ? 'مواقيت الصلاة' : 'Prayer times', arabic ? 'المواقيت والإعدادات' : 'Prayer schedule and settings', AppRoutes.prayer),
          (material.Icons.settings_outlined, arabic ? 'الإعدادات' : 'Settings', arabic ? 'اللغة والتنبيهات والمظهر' : 'Language, reminders and appearance', AppRoutes.settings),
        ]),
      ];
      return AdaptivePageScaffold(
        navigationBar: material.AppBar(title: Text(arabic ? 'المزيد' : 'More')),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              for (final group in groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                  child: Text(group.$1.toUpperCase(),
                    style: material.Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.1, fontWeight: FontWeight.w700)),
                ),
                material.Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < group.$2.length; i++) ...[
                        if (i > 0) const material.Divider(height: 1),
                        material.ListTile(
                          leading: Icon(group.$2[i].$1),
                          title: Text(group.$2[i].$2),
                          subtitle: Text(group.$2[i].$3),
                          trailing: const Icon(material.Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pushNamed(group.$2[i].$4),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return AdaptivePageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(LocaleController.isArabic ? 'المزيد' : 'More')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
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
                  leading: const Icon(CupertinoIcons.book),
                  title: Text(LocaleController.isArabic ? 'الورد اليومي' : 'Daily Quran wird'),
                  subtitle: Text(LocaleController.isArabic ? 'هدف قراءة متتابع وختمة منظمة' : 'A continuous daily Quran reading plan'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.dailyWird),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.book_fill),
                  title: Text(LocaleController.isArabic ? 'حفظ القرآن' : 'Quran memorization'),
                  subtitle: Text(LocaleController.isArabic ? 'حفظ الآيات وتتبع المراجعة دون إنترنت' : 'Practice ayahs and track revision offline'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.quranMemorization),
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
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.qibla),
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
                  leading: const Icon(CupertinoIcons.gift, color: AppTheme.antiqueGold),
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
