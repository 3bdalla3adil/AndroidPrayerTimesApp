import 'package:flutter/cupertino.dart';

import '../services/storage_service.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  final _storage = StorageService();
  int _count = 0;
  int _target = 33;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.loadTasbih();
    if (!mounted) return;
    setState(() {
      _count = saved.$1;
      _target = saved.$2;
      _loading = false;
    });
  }

  Future<void> _increment() async {
    final next = _count + 1;
    setState(() => _count = next);
    await _storage.saveTasbih(next, _target);
  }

  Future<void> _reset() async {
    setState(() => _count = 0);
    await _storage.saveTasbih(0, _target);
  }

  Future<void> _setTarget(int target) async {
    setState(() {
      _target = target;
      _count = 0;
    });
    await _storage.saveTasbih(0, target);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Tasbih')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final progress = _target == 0 ? 0.0 : (_count / _target).clamp(0.0, 1.0);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Tasbih'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _reset,
          child: const Text('Reset'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          children: [
            const Text(
              'سبحان الله',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Offline counter • progress is saved on this device',
              textAlign: TextAlign.center,
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _increment,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.activeGreen.resolveFrom(context),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_count',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'of $_target',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tap to count',
                      style: TextStyle(color: CupertinoColors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            CupertinoSlider(
              value: progress,
              onChanged: (_) {},
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('TARGET'),
              children: [
                for (final target in const [33, 99, 100])
                  CupertinoListTile(
                    title: Text('$target repetitions'),
                    trailing: _target == target
                        ? const Icon(CupertinoIcons.check_mark)
                        : null,
                    onTap: () => _setTarget(target),
                  ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.arrow_counterclockwise),
                  title: const Text('Reset counter'),
                  onTap: _reset,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
