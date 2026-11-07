import 'package:flutter/cupertino.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  final _storage = StorageService();
  int _count = 0;
  int _target = 33;
  String _dhikr = 'سبحان الله';
  Map<String, int> _counts = {};
  bool _loading = true;

  int get _count => _counts[_dhikr] ?? 0;

  static const _dhikrOptions = <(String, String)>[
    ('سبحان الله', 'SubhanAllah'),
    ('الحمد لله', 'Alhamdulillah'),
    ('الله أكبر', 'Allahu Akbar'),
    ('لا إله إلا الله', 'La ilaha illallah'),
    ('أستغفر الله', 'Astaghfirullah'),
    ('سبحان الله وبحمده', 'SubhanAllahi wa bihamdihi'),
    ('سبحان الله العظيم', 'SubhanAllahil Adheem'),
    ('لا حول ولا قوة إلا بالله', 'La hawla wa la quwwata illa billah'),
    ('اللهم صل وسلم على نبينا محمد', 'Allahumma salli wa sallim ala nabiyyina Muhammad'),
    ('لا إله إلا أنت سبحانك إني كنت من الظالمين', 'La ilaha illa Anta, subhanaka inni kuntu minaz-zalimin'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.loadTasbih();
    final dhikr = await _storage.loadTasbihDhikr();
    final counts = await _storage.loadTasbihCounts();
    if (!counts.containsKey(dhikr)) counts[dhikr] = saved.$1;
    if (!mounted) return;
    setState(() {
      _counts = counts;
      _target = saved.$2;
      _dhikr = _dhikrOptions.any((item) => item.$1 == dhikr) ? dhikr : _dhikrOptions.first.$1;
      _loading = false;
    });
  }

  Future<void> _increment() async {
    if (_count >= _target) return;
    final next = _count + 1;
    setState(() => _counts[_dhikr] = next);
    await _storage.saveTasbihCounts(_counts);
    await _storage.saveTasbih(next, _target);
    if (next == _target && mounted) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('تم الوصول إلى الهدف'),
          content: Text('ما شاء الله، أكملت $_target تسبيحة.\n\nلقد وصلت إلى الهدف المحدد.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('تم'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _chooseCustomTarget() async {
    final controller = TextEditingController(text: '33');
    final selected = await showCupertinoDialog<int>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('هدف مخصص'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            placeholder: '1 - 10000',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value >= 1 && value <= 10000) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (selected != null) await _setTarget(selected);
  }

  Future<void> _chooseDhikr() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: const Text('اختر الذكر'),
        message: const Text('اختيار ذكر جديد يبدأ عدّادًا جديدًا له.'),
        actions: [
          for (final item in _dhikrOptions)
            CupertinoActionSheetAction(
              isDefaultAction: item.$1 == _dhikr,
              onPressed: () {
                Navigator.pop(popupContext);
                _selectDhikr(item.$1);
              },
              child: Column(
                children: [
                  Text(item.$1, textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 19)),
                  Text(item.$2, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(popupContext),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Future<void> _selectDhikr(String dhikr) async {
    if (dhikr == _dhikr) return;
    setState(() => _dhikr = dhikr);
    await _storage.saveTasbihDhikr(dhikr);
  }

  Future<void> _reset() async {
    setState(() => _counts[_dhikr] = 0);
    await _storage.saveTasbihCounts(_counts);
    await _storage.saveTasbih(0, _target);
  }

  Future<void> _setTarget(int target) async {
    setState(() {
      _target = target;
      _counts[_dhikr] = 0;
    });
    await _storage.saveTasbihCounts(_counts);
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
            Text(
              _dhikr,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.6),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              onPressed: _chooseDhikr,
              child: const Text('تغيير الذكر  •  CHOOSE DHIKR'),
            ),
            const SizedBox(height: 8),
            const Text(
              'عداد أذكار يعمل دون إنترنت • يُحفظ التقدم على جهازك',
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
                  color: AppTheme.emerald,
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
                      'اضغط للعدّ',
                      style: TextStyle(color: CupertinoColors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 8,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.emerald,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('الهدف الشخصي • PERSONAL GOAL'),
              children: [
                for (final target in const [33, 99, 100])
                  CupertinoListTile(
                    title: Text('$target تكرارًا'),
                    trailing: _target == target
                        ? const Icon(CupertinoIcons.check_mark)
                        : null,
                    onTap: () => _setTarget(target),
                  ),
                CupertinoListTile(
                  title: const Text('هدف مخصص'),
                  subtitle: Text('$_target تكرارًا'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _chooseCustomTarget,
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.arrow_counterclockwise),
                  title: const Text('إعادة ضبط العداد'),
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
