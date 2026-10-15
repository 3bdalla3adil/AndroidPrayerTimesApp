import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/app_routes.dart';
import 'services/locale_controller.dart';
import 'services/notification_service.dart';
import 'services/root_tab_navigation.dart';
import 'theme/app_theme.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late final CupertinoTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CupertinoTabController();
    NotificationService.lastPayload.addListener(_handleNotificationPayload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOpeningDedication();
      _handleNotificationPayload();
    });
  }

  void _handleNotificationPayload() {
    final payload = NotificationService.lastPayload.value;
    if (payload == null || !payload.startsWith('prayer:')) return;
    if (mounted) _controller.index = 2;
    NotificationService.clearLastPayload();
  }

  /// Presents the app's dedication on every fresh launch without blocking
  /// access to the main app after the user dismisses it.
  Future<void> _showOpeningDedication() async {
    if (!mounted) return;
    final arabic = LocaleController.isArabic;
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Column(
          children: [
            const SizedBox(height: 4),
            const Icon(
              CupertinoIcons.gift_fill,
              size: 30,
              color: AppTheme.antiqueGold,
            ),
            const SizedBox(height: 10),
            Text(
              arabic ? 'إهداء وتقدير' : 'A Gift of Gratitude',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFE7A3),
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              arabic ? 'كلمات من القلب' : 'A Note from the Heart',
              style: const TextStyle(
                color: Color(0xFFD2C8AF),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 350),
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.fromLTRB(15, 18, 15, 16),
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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.antiqueGold, width: 1),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(
                  CupertinoIcons.sparkles,
                  size: 17,
                  color: AppTheme.antiqueGold,
                ),
                const SizedBox(height: 12),
                Text(
                  arabic
                      ? 'إلى والد زوجتي العزيز، وأمير قلبها،'
                      : 'To my dear father-in-law, and the cherished father of my beloved,',
                  textAlign: TextAlign.center,
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(
                    color: Color(0xFFFFE7A3),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  arabic
                      ? 'أهديك هذه الكلمات المتواضعة تقديرًا لمقامك، واحترامًا لشخصك الكريم، وامتنانًا للمكانة العزيزة التي تحملها في قلوبنا.\n\nلك مني خالص التقدير وصادق الدعاء؛ أسأل الله أن يبارك في عمرك وصحتك، وأن يجزيك خير الجزاء، ويديم عليك السكينة والرضا، ويحفظ لك من تحب.\n\nقد لا تفي الكلمات حقك، لكنها تحمل احترامًا صادقًا ومودةً خالصة.'
                      : 'Please accept this humble dedication as a sign of my respect for you and gratitude for the valued place you hold in our family.\n\nWith sincere appreciation and prayers, may Allah bless you with health, a long life filled with goodness, peace of heart, and the happiness of those you love.\n\nWords may never fully express my esteem, but these come with genuine respect and affection.',
                  textAlign: TextAlign.center,
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(
                    color: Color(0xFFF5F0E4),
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 70,
                  height: 1,
                  color: AppTheme.antiqueGold.withValues(alpha: .75),
                ),
                const SizedBox(height: 10),
                Text(
                  arabic
                      ? 'اللهم احفظه وبارك له، واجزه عن أهله ومحبيه خيرًا.'
                      : 'May Allah protect him, bless him, and reward him with goodness.',
                  textAlign: TextAlign.center,
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(
                    color: Color(0xFFFFE7A3),
                    fontSize: 12,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              arabic ? 'الدخول إلى التطبيق' : 'Enter app',
              style: const TextStyle(
                color: AppTheme.antiqueGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    NotificationService.lastPayload.removeListener(_handleNotificationPayload);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen here as well as at the app root so tab labels refresh immediately
    // when the user changes language from Settings.
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) => RootTabNavigation(
        controller: _controller,
        child: CupertinoTabScaffold(
          controller: _controller,
          tabBar: CupertinoTabBar(
            items: [
              BottomNavigationBarItem(
                icon: const KeyedSubtree(
                  key: ValueKey('home-tab'),
                  child: Icon(CupertinoIcons.house),
                ),
                label: locale.languageCode == 'ar' ? 'الرئيسية' : 'Home',
              ),
              BottomNavigationBarItem(
                icon: const KeyedSubtree(
                  key: ValueKey('quran-tab'),
                  child: Icon(CupertinoIcons.book),
                ),
                label: locale.languageCode == 'ar' ? 'القرآن' : 'Quran',
              ),
              BottomNavigationBarItem(
                icon: const KeyedSubtree(
                  key: ValueKey('prayer-tab'),
                  child: Icon(CupertinoIcons.time),
                ),
                label: locale.languageCode == 'ar' ? 'الصلاة' : 'Prayer',
              ),
              BottomNavigationBarItem(
                icon: const KeyedSubtree(
                  key: ValueKey('qibla-tab'),
                  child: Icon(CupertinoIcons.compass),
                ),
                label: locale.languageCode == 'ar' ? 'القبلة' : 'Qibla',
              ),
              BottomNavigationBarItem(
                icon: const KeyedSubtree(
                  key: ValueKey('more-tab'),
                  child: Icon(CupertinoIcons.ellipsis_circle),
                ),
                label: locale.languageCode == 'ar' ? 'المزيد' : 'More',
              ),
            ],
          ),
          tabBuilder: (context, index) => CupertinoTabView(
            // Each tab has a named root route, and every secondary screen is
            // resolved by the same central route table.
            builder: (_) => AppRoutes.tabScreenForIndex(index),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        ),
      ),
    );
  }
}

class SalawatQuranApp extends StatelessWidget {
  const SalawatQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep the test/embedded app entry point visually and behaviorally
    // identical to the production Cupertino app.
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) => CupertinoApp(
        title: locale.languageCode == 'ar' ? 'صلوات' : 'Salawat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.data,
        locale: locale,
        localizationsDelegates: const [
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        home: const RootShell(),
      ),
    );
  }
}
