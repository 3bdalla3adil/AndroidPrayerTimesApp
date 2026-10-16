import 'package:flutter/cupertino.dart';

import '../services/locale_controller.dart';
import '../theme/app_theme.dart';

/// A quiet, animated dedication card to express gratitude and respect.
class DedicationScreen extends StatefulWidget {
  const DedicationScreen({super.key});

  @override
  State<DedicationScreen> createState() => _DedicationScreenState();
}

class _DedicationScreenState extends State<DedicationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = LocaleController.isArabic;
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF071F1A),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xEE071F1A),
        border: null,
        middle: Text(
          isArabic ? 'إهداء وتقدير' : 'A Gift of Gratitude',
          style: const TextStyle(color: Color(0xFFF7E8BD)),
        ),
        previousPageTitle: isArabic ? 'المزيد' : 'More',
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
          children: [
            const SizedBox(height: 8),
            Icon(
              CupertinoIcons.gift_fill,
              size: 38,
              color: AppTheme.antiqueGold,
              semanticLabel: isArabic ? 'هدية تقدير' : 'Gift of appreciation',
            ),
            const SizedBox(height: 14),
            Text(
              isArabic ? 'كلمات من القلب' : 'A Note from the Heart',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF7E8BD),
                fontSize: 25,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'إهداء متواضع يحمل أصدق معاني الاحترام والامتنان'
                  : 'A humble dedication, offered with sincere respect and gratitude',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD2C8AF),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: _glow,
              builder: (context, child) {
                final glow = 0.12 + (_glow.value * 0.14);
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.antiqueGold.withValues(alpha: glow),
                        blurRadius: 18 + (_glow.value * 16),
                        spreadRadius: 1 + (_glow.value * 2),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1C5948),
                      Color(0xFF103C32),
                      Color(0xFF0C2C25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.antiqueGold.withValues(alpha: 0.85),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    const _GoldDivider(),
                    const SizedBox(height: 24),
                    Text(
                      isArabic
                          ? 'إلى والد زوجتي العزيز، وأمير قلبها،'
                          : 'To my dear father-in-law, and the cherished father of my beloved,',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFE7A3),
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isArabic
                          ? 'أهديك هذه الكلمات المتواضعة تقديرًا لمقامك، واحترامًا لشخصك الكريم، وامتنانًا للمكانة العزيزة التي تحملها في قلوبنا.\n\nلك مني خالص التقدير وصادق الدعاء؛ أسأل الله أن يبارك في عمرك وصحتك، وأن يجزيك خير الجزاء، ويديم عليك السكينة والرضا، ويحفظ لك من تحب.\n\nقد لا تفي الكلمات حقك، لكنها تحمل احترامًا صادقًا ومودةً خالصة.'
                          : 'Please accept this humble dedication as a sign of my respect for you and gratitude for the valued place you hold in our family.\n\nWith sincere appreciation and prayers, may Allah bless you with health, a long life filled with goodness, peace of heart, and the happiness of those you love.\n\nWords may never fully express my esteem, but these come with genuine respect and affection.',
                      textAlign: TextAlign.center,
                      textDirection:
                          isArabic ? TextDirection.rtl : TextDirection.ltr,
                      style: const TextStyle(
                        color: Color(0xFFF5F0E4),
                        fontSize: 17,
                        height: 2.0,
                        letterSpacing: 0.05,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _GoldDivider(),
                    const SizedBox(height: 18),
                    Icon(
                      CupertinoIcons.heart_fill,
                      color: AppTheme.antiqueGold.withValues(alpha: 0.95),
                      size: 22,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isArabic ? 'بكل احترام وامتنان' : 'With respect and gratitude',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFE7A3),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isArabic
                  ? 'اللهم احفظه وبارك له، واجزه عن أهله ومحبيه خيرًا.'
                  : 'May Allah protect him, bless him, and reward him with goodness.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD2C8AF),
                fontSize: 14,
                height: 1.8,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.antiqueGold.withValues(alpha: 0.6),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              CupertinoIcons.sparkles,
              size: 18,
              color: AppTheme.antiqueGold,
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.antiqueGold.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
}
