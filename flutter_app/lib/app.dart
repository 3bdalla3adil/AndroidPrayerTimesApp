import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
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
  late final ValueNotifier<int> _materialIndex;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _controller = CupertinoTabController();
    _materialIndex = ValueNotifier<int>(0);
    NotificationService.lastPayload.addListener(_handleNotificationPayload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOpeningDedication();
      _handleNotificationPayload();
    });
  }

  bool _openingDedicationShown = false;

  Future<void> _showOpeningDedication() async {
    if (_openingDedicationShown || !mounted) return;
    _openingDedicationShown = true;
    final isArabic = LocaleController.isArabic;
    const background = Color(0xFF103C32);
    const gold = Color(0xFFFFE7A3);
    const bodyColor = Color(0xFFF5F0E4);
    if (_isIOS) {
      await showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Column(
            children: [
              const Icon(CupertinoIcons.gift_fill, color: Color(0xFFC7A45A), size: 28),
              const SizedBox(height: 8),
              Text(isArabic ? 'إهداء وتقدير — كلمات من القلب' : 'A Gift of Gratitude'),
            ],
          ),
          content: SizedBox(
            height: 300,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  isArabic
                      ? 'إلى والد زوجتي العزيز، وأمير قلبها،\\n\\nأهديك هذه الكلمات المتواضعة تقديرًا لمقامك، واحترامًا لشخصك الكريم، وامتنانًا للمكانة العزيزة التي تحملها في قلوبنا.\\n\\nلك مني خالص التقدير وصادق الدعاء؛ أسأل الله أن يبارك في عمرك وصحتك، وأن يجزيك خير الجزاء، ويديم عليك السكينة والرضا، ويحفظ لك من تحب.\\n\\nقد لا تفي الكلمات حقك، لكنها تحمل احترامًا صادقًا ومودةً خالصة.'
                      : 'To my dear father-in-law, and the cherished father of my beloved,\\n\\nPlease accept this humble dedication as a sign of my respect for you and gratitude for the valued place you hold in our family.\\n\\nWith sincere appreciation and prayers, may Allah bless you with health, a long life filled with goodness, peace of heart, and the happiness of those you love.\\n\\nWords may never fully express my esteem, but these come with genuine respect and affection.',
                  textAlign: TextAlign.center,
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(height: 1.8),
                ),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(isArabic ? 'الدخول إلى التطبيق' : 'Enter app'),
            ),
          ],
        ),
      );
      return;
    }
    await material.showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => material.AlertDialog(
        backgroundColor: background,
        icon: const Icon(CupertinoIcons.gift_fill, color: Color(0xFFC7A45A), size: 30),
        title: Text(
          isArabic ? 'إهداء وتقدير — كلمات من القلب' : 'A Gift of Gratitude',
          textAlign: TextAlign.center,
          style: const TextStyle(color: gold, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          height: 300,
          width: 420,
          child: SingleChildScrollView(
            child: Text(
              isArabic
                  ? 'إلى والد زوجتي العزيز، وأمير قلبها،\\n\\nأهديك هذه الكلمات المتواضعة تقديرًا لمقامك، واحترامًا لشخصك الكريم، وامتنانًا للمكانة العزيزة التي تحملها في قلوبنا.\\n\\nلك مني خالص التقدير وصادق الدعاء؛ أسأل الله أن يبارك في عمرك وصحتك، وأن يجزيك خير الجزاء، ويديم عليك السكينة والرضا، ويحفظ لك من تحب.\\n\\nقد لا تفي الكلمات حقك، لكنها تحمل احترامًا صادقًا ومودةً خالصة.'
                  : 'To my dear father-in-law, and the cherished father of my beloved,\\n\\nPlease accept this humble dedication as a sign of my respect for you and gratitude for the valued place you hold in our family.\\n\\nWith sincere appreciation and prayers, may Allah bless you with health, a long life filled with goodness, peace of heart, and the happiness of those you love.\\n\\nWords may never fully express my esteem, but these come with genuine respect and affection.',
              textAlign: TextAlign.center,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(color: bodyColor, height: 1.8),
            ),
          ),
        ),
        actions: [
          material.FilledButton(
            style: material.FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC7A45A),
              foregroundColor: const Color(0xFF071F1A),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(isArabic ? 'الدخول إلى التطبيق' : 'Enter app'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationPayload() {
    final payload = NotificationService.lastPayload.value;
    if (payload == null || !payload.startsWith('prayer:')) return;
    if (mounted) {
      _controller.index = 2;
      _materialIndex.value = 2;
    }
    NotificationService.clearLastPayload();
  }

  @override
  void dispose() {
    NotificationService.lastPayload.removeListener(_handleNotificationPayload);
    _controller.dispose();
    _materialIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final labels = locale.languageCode == 'ar'
            ? const ['الرئيسية', 'القرآن', 'الصلاة', 'القبلة', 'المزيد']
            : const ['Home', 'Quran', 'Prayer', 'Qibla', 'More'];
        const icons = <IconData>[
          CupertinoIcons.house,
          CupertinoIcons.book,
          CupertinoIcons.time,
          CupertinoIcons.compass,
          CupertinoIcons.ellipsis_circle,
        ];
        const tabKeys = ['home-tab', 'quran-tab', 'prayer-tab', 'qibla-tab', 'more-tab'];

        if (!_isIOS) {
          return RootTabNavigation(
            controller: _controller,
            materialIndex: _materialIndex,
            child: ValueListenableBuilder<int>(
              valueListenable: _materialIndex,
              builder: (context, selectedIndex, _) => material.Scaffold(
                body: IndexedStack(
                  index: selectedIndex,
                  children: List<Widget>.generate(
                    AppRoutes.tabRoutes.length,
                    AppRoutes.tabScreenForIndex,
                  ),
                ),
                bottomNavigationBar: material.NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    _controller.index = index;
                    _materialIndex.value = index;
                  },
                  destinations: List<material.NavigationDestination>.generate(
                    labels.length,
                    (index) => material.NavigationDestination(
                      key: ValueKey(tabKeys[index]),
                      icon: Icon(icons[index]),
                      label: labels[index],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return RootTabNavigation(
          controller: _controller,
          materialIndex: _materialIndex,
          child: CupertinoTabScaffold(
            controller: _controller,
            tabBar: CupertinoTabBar(
              items: List<BottomNavigationBarItem>.generate(
                labels.length,
                (index) => BottomNavigationBarItem(
                  icon: KeyedSubtree(
                    key: ValueKey(tabKeys[index]),
                    child: Icon(icons[index]),
                  ),
                  label: labels[index],
                ),
              ),
            ),
            tabBuilder: (context, index) => CupertinoTabView(
              builder: (_) => AppRoutes.tabScreenForIndex(index),
              onGenerateRoute: AppRoutes.onGenerateRoute,
            ),
          ),
        );
      },
    );
  }
}

class SalawatQuranApp extends StatelessWidget {
  const SalawatQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
        if (isIOS) {
          return CupertinoApp(
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
          );
        }

        return material.MaterialApp(
          title: locale.languageCode == 'ar' ? 'صلوات' : 'Salawat',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.materialData,
          darkTheme: AppTheme.materialDarkData,
          themeMode: material.ThemeMode.system,
          locale: locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const RootShell(),
        );
      },
    );
  }
}
