import 'package:flutter/cupertino.dart';
import 'package:quran/quran.dart' as quran;
import '../services/storage_service.dart';
import 'quran_reader_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});
  @override State<BookmarksScreen> createState() => _BookmarksScreenState();
}
class _BookmarksScreenState extends State<BookmarksScreen> {
  final _storage = StorageService();
  List<(int, int)> _bookmarks = const [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final values = await _storage.loadBookmarks();
    if (!mounted) return;
    setState(() { _bookmarks = values.reversed.toList(); _loading = false; });
  }

  Future<void> _remove((int, int) bookmark) async {
    final values = await _storage.loadBookmarks();
    values.removeWhere((b) => b.$1 == bookmark.$1 && b.$2 == bookmark.$2);
    await _storage.saveBookmarks(values);
    await _load();
  }

  Future<void> _confirmRemove((int, int) bookmark) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Remove bookmark?'),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(dialogContext)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Remove'),
            onPressed: () { Navigator.pop(dialogContext); _remove(bookmark); },
          ),
        ],
      ),
    );
  }

  @override Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Bookmarks')),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _bookmarks.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.bookmark, size: 46),
                          SizedBox(height: 14),
                          Text('No bookmarks yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          SizedBox(height: 6),
                          Text('Bookmark an ayah while reading and it will appear here.', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
                    children: [
                      CupertinoListSection.insetGrouped(
                        children: [
                          for (final bookmark in _bookmarks)
                            CupertinoListTile(
                              leading: const Icon(CupertinoIcons.bookmark_fill),
                              title: Text(quran.getSurahName(bookmark.$1)),
                              subtitle: Text(
                                'Ayah ' + bookmark.$2.toString() + ': ' + quran.getVerse(bookmark.$1, bookmark.$2),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                              ),
                              trailing: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _confirmRemove(bookmark),
                                child: const Icon(CupertinoIcons.trash),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => QuranReaderScreen(surahNumber: bookmark.$1, startingAyah: bookmark.$2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}
