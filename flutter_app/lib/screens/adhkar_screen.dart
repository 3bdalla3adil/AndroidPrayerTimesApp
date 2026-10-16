import 'package:flutter/cupertino.dart';
import '../core/adaptive_page_scaffold.dart';
import '../services/locale_controller.dart';
import '../theme/app_theme.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  static const _items = <(String, String, int)>[
    ('أستغفر الله', 'Astaghfirullah', 3),
    ('سبحان الله وبحمده', 'SubhanAllahi wa bihamdihi', 10),
    ('لا إله إلا الله وحده لا شريك له', 'La ilaha illallahu wahdahu la sharika lah', 10),
    ('اللهم صل وسلم على نبينا محمد', 'Allahumma salli wa sallim ala nabiyyina Muhammad', 10),
    ('حسبي الله لا إله إلا هو عليه توكلت', 'Hasbiyallahu la ilaha illa Huwa, alayhi tawakkaltu', 7),
    ('سبحان الله والحمد لله والله أكبر', 'SubhanAllah, Alhamdulillah, Allahu Akbar', 33),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptivePageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(LocaleController.isArabic ? 'الأذكار اليومية' : 'Daily Adhkar')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
          children: [
            Text(LocaleController.isArabic ? 'أذكار يومية' : 'Daily Adhkar', textDirection: LocaleController.isArabic ? TextDirection.rtl : TextDirection.ltr, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: CupertinoColors.label.resolveFrom(context))),
            const SizedBox(height: 6),
            Text(LocaleController.isArabic ? 'مجموعة مختارة للذكر اليومي دون إنترنت' : 'A small offline collection for daily remembrance.',
              textAlign: TextAlign.center, style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
            const SizedBox(height: 18),
            for (final item in _items)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: .35)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emerald.withValues(alpha: CupertinoTheme.brightnessOf(context) == Brightness.dark ? .12 : .06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(item.$1, textDirection: TextDirection.rtl, textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 22, height: 1.8, fontWeight: FontWeight.w700,
                        color: CupertinoColors.label.resolveFrom(context))),
                    const SizedBox(height: 8),
                    Text(item.$2, textDirection: TextDirection.ltr,
                      style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(CupertinoIcons.repeat, size: 16,
                          color: CupertinoTheme.brightnessOf(context) == Brightness.dark ? const Color(0xFF82D6B2) : AppTheme.emerald),
                        const SizedBox(width: 6),
                        Text(LocaleController.isArabic ? 'العدد المقترح: ${item.$3}' : 'Suggested count: ${item.$3}',
                          style: TextStyle(fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
