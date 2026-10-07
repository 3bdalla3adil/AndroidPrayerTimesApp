import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:quran/quran.dart' as quran;

import '../services/storage_service.dart';
import 'quran_reader_screen.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  final _storage = StorageService();
  List<(int, int, DateTime)> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _storage.loadReadingHistory();
    if (!mounted) return;
    setState(() {
      _history = history.reversed.toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Reading history'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _load,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _history.isEmpty
                ? const Center(
                    child: Text('Your recent Quran reading will appear here.'),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
                    children: [
                      CupertinoListSection.insetGrouped(
                        header: const Text('RECENT'),
                        children: [
                          for (final item in _history)
                            CupertinoListTile(
                              leading: const Icon(CupertinoIcons.book),
                              title: Text(quran.getSurahName(item.$1)),
                              subtitle: Text('Ayah ${item.$2} • ${DateFormat('d MMM, h:mm a').format(item.$3)}'),
                              trailing: const CupertinoListTileChevron(),
                              onTap: () => Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => QuranReaderScreen(
                                    surahNumber: item.$1,
                                    startingAyah: item.$2,
                                  ),
                                ),
                              ).then((_) => _load()),
                            ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}
