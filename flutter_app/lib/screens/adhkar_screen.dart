import 'package:flutter/cupertino.dart';

import '../core/adaptive_page_scaffold.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  static const _items = <(String, String, int)>[
    ('أستغفر الله', 'Astaghfirullah', 3),
    ('سبحان الله وبحمده', 'SubhanAllahi wa bihamdihi', 10),
    ('لا إله إلا الله وحده لا شريك له', 'La ilaha illallahu wahdahu la sharika lah', 10),
    ('اللهم صل وسلم على نبينا محمد', 'Allahumma salli wa sallim ala nabiyyina Muhammad', 10),
    ('حسبي الله لا إله إلا هو عليه توكلت', 'Hasbiyallahu la ilaha illa Huwa, alayhi tawakkaltu', 7),
    ('سبحان الله والحمد لله والله أكبر', 'SubhanAllah, Alhamdulillah, Allahu Akbar', 33),
  ];

  final _storage = StorageService();
  Map<String, int> _progress = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await _storage.loadAdhkarProgress();
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _loading = false;
    });
  }

  Future<void> _changeCount(int index, int delta) async {
    if (_saving) return;
    final id = index.toString();
    final current = _progress[id] ?? 0;
    final next = (current + delta).clamp(0, _items[index].$3);
    if (next == current) return;

    final updated = Map<String, int>.from(_progress);
    if (next == 0) {
      updated.remove(id);
    } else {
      updated[id] = next;
    }
    setState(() {
      _progress = updated;
      _saving = true;
    });
    try {
      await _storage.saveAdhkarProgress(updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetToday() async {
    if (_saving || _progress.isEmpty) return;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Reset today’s progress?'),
        content: const Text('All completed repetitions for today will be cleared.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _progress = {};
      _saving = true;
    });
    try {
      await _storage.saveAdhkarProgress(const {});
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _items.asMap().entries.fold<int>(
      0,
      (total, entry) => total +
          ((_progress[entry.key.toString()] ?? 0).clamp(0, entry.value.$3).toInt()),
    );
    final target = _items.fold<int>(0, (total, item) => total + item.$3);
    final finished = _items.where((item) {
      final index = _items.indexOf(item);
      return (_progress[index.toString()] ?? 0) >= item.$3;
    }).length;
    final fraction = target == 0 ? 0.0 : completed / target;

    return AdaptivePageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Daily Adhkar'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _loading || _saving || _progress.isEmpty ? null : _resetToday,
          child: const Text('Reset'),
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
                children: [
                  const Text(
                    'أذكار يومية',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A small offline collection for daily remembrance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                  const SizedBox(height: 18),
                  CupertinoListSection.insetGrouped(
                    header: const Text('TODAY’S PROGRESS'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$completed / $target repetitions'),
                                Text('$finished / ${_items.length} completed'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _ProgressBar(
                              value: fraction,
                              color: AppTheme.emerald,
                              height: 8,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Progress is saved on this device and starts fresh each local calendar day.',
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  for (var index = 0; index < _items.length; index++)
                    _AdhkarCard(
                      arabic: _items[index].$1,
                      transliteration: _items[index].$2,
                      target: _items[index].$3,
                      count: (_progress[index.toString()] ?? 0).clamp(0, _items[index].$3).toInt(),
                      onIncrement: () => _changeCount(index, 1),
                      onDecrement: () => _changeCount(index, -1),
                    ),
                ],
              ),
      ),
    );
  }
}

class _AdhkarCard extends StatelessWidget {
  const _AdhkarCard({
    required this.arabic,
    required this.transliteration,
    required this.target,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String arabic;
  final String transliteration;
  final int target;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final complete = count >= target;
    return CupertinoListSection.insetGrouped(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                transliteration,
                textAlign: TextAlign.center,
                style: const TextStyle(color: CupertinoColors.secondaryLabel),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$count / $target',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: complete ? AppTheme.emerald : null,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: count == 0 ? null : onDecrement,
                    child: const Icon(CupertinoIcons.minus_circle),
                  ),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    onPressed: complete ? null : onIncrement,
                    child: Text(complete ? 'Done' : 'Count'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _ProgressBar(
                value: count / target,
                color: complete ? AppTheme.emerald : CupertinoColors.activeBlue,
                height: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.color,
    required this.height,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        width: double.infinity,
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: ColoredBox(color: color),
        ),
      ),
    );
  }
}
