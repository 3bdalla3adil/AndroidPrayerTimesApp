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
    const background = Color(0xFF071F1A);
    const cardColor = Color(0xFF103C32);
    const gold = Color(0xFFFFE7A3);
    const mutedGold = Color(0xFFC7A45A);
    const bodyColor = Color(0xFFF5F0E4);
    final dedication = isArabic
        ? 'إلى والد زوجتي العزيز، وأمير قلبها،\n\nأهديك هذه الكلمات المتواضعة تقديرًا لمقامك، واحترامًا لشخصك الكريم، وامتنانًا للمكانة العزيزة التي تحملها في قلوبنا.\n\nلك مني خالص التقدير وصادق الدعاء؛ أسأل الله أن يبارك في عمرك وصحتك، وأن يجزيك خير الجزاء، ويديم عليك السكينة والرضا، ويحفظ لك من تحب.\n\nقد لا تفي الكلمات حقك، لكنها تحمل احترامًا صادقًا ومودةً خالصة.'
        : 'To my dear father-in-law, and the cherished father of my beloved,\n\nPlease accept this humble dedication as a sign of my respect for you and gratitude for the valued place you hold in our family.\n\nWith sincere appreciation and prayers, may Allah bless you with health, a long life filled with goodness, peace of heart, and the happiness of those you love.\n\nWords may never fully express my esteem, but these come with genuine respect and affection.';

    await material.showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: isArabic ? 'إهداء وتقدير' : 'A Gift of Gratitude',
      barrierColor: const Color(0xE6000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return material.Material(
          color: background,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.gift_fill,
                          color: mutedGold,
                          size: 38,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isArabic ? 'إهداء وتقدير' : 'A Gift of Gratitude',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: gold,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isArabic ? 'كلمات من القلب' : 'A Note from the Heart',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: mutedGold,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1C5948),
                                  cardColor,
                                  Color(0xFF0C2C25),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: mutedGold, width: 1.2),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.sparkles,
                                    color: gold,
                                    size: 22,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    isArabic
                                        ? 'إلى والد زوجتي العزيز، وأمير قلبها،'
                                        : 'To my dear father-in-law, and the cherished father of my beloved,',
                                    textAlign: TextAlign.center,
                                    textDirection: isArabic
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                    style: const TextStyle(
                                      color: gold,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      height: 1.7,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    dedication.substring(dedication.indexOf('\n\n') + 4),
                                    textAlign: TextAlign.center,
                                    textDirection: isArabic
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                    style: const TextStyle(
                                      color: bodyColor,
                                      fontSize: 17,
                                      height: 1.9,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const material.Divider(color: mutedGold),
                                  const SizedBox(height: 14),
                                  Text(
                                    isArabic
                                        ? 'بكل احترام وامتنان'
                                        : 'With respect and gratitude',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: gold,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: material.FilledButton(
                            style: material.FilledButton.styleFrom(
                              backgroundColor: mutedGold,
                              foregroundColor: const Color(0xFF071F1A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(
                              isArabic ? 'الدخول إلى التطبيق' : 'Enter app',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
            child: child,
          ),
        );
      },
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
