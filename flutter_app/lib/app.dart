import 'package:flutter/cupertino.dart';

import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/quran_screen.dart';
import 'services/notification_service.dart';
import 'services/biometric_service.dart';
import 'services/storage_service.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  late final CupertinoTabController _controller;
  final _storage = StorageService();
  final _biometric = BiometricService();
  bool _locked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = CupertinoTabController();
    NotificationService.lastPayload.addListener(_handleNotificationPayload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationPayload();
      _authenticateIfRequired();
    });
  }

  void _handleNotificationPayload() {
    final payload = NotificationService.lastPayload.value;
    if (payload == null || !payload.startsWith('prayer:')) return;
    if (mounted) _controller.index = 2;
    NotificationService.clearLastPayload();
  }

  Future<void> _authenticateIfRequired() async {
    if (_authenticating) return;
    final enabled = await _storage.loadBiometricLockEnabled();
    if (!enabled || !mounted) return;
    setState(() => _locked = true);
    await _authenticate();
  }

  Future<void> _authenticate() async {
    if (_authenticating || !mounted) return;
    setState(() => _authenticating = true);
    final ok = await _biometric.authenticate();
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      _locked = !ok;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _authenticateIfRequired();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.lastPayload.removeListener(_handleNotificationPayload);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CupertinoTabScaffold(
          controller: _controller,
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.book), label: 'Quran'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.time), label: 'Prayer'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.compass), label: 'Qibla'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.ellipsis_circle), label: 'More'),
        ],
      ),
      tabBuilder: (context, index) {
        final pages = <Widget>[
          const HomeScreen(),
          const QuranScreen(),
          const PrayerScreen(),
          const QiblaScreen(),
          const MoreScreen(),
        ];
        return CupertinoTabView(builder: (_) => pages[index]);
      },
    );
  }
}

class SalawatQuranApp extends StatelessWidget {
  const SalawatQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: RootShell(),
        ),
        if (_locked)
          Positioned.fill(
            child: ColoredBox(
              color: CupertinoColors.systemBackground,
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.lock_shield, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        'App locked',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text('Authenticate to continue.'),
                      const SizedBox(height: 20),
                      CupertinoButton.filled(
                        onPressed: _authenticating ? null : _authenticate,
                        child: Text(
                          _authenticating ? 'Waiting…' : 'Unlock with biometrics',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
