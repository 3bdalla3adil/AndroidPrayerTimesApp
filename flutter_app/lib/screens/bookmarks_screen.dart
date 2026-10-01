import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../services/storage_service.dart';
import 'quran_reader_screen.dart';
/*
Run flutter analyze --fatal-warnings
Analyzing flutter_app...                                        

   info • Unnecessary use of multiple underscores. Try using '_' • lib/screens/bookmarks_screen.dart:71:41 • unnecessary_underscores [X]
  
*/
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _storage = StorageService();
  List<(int, int)> _bookmarks = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookmarks = await _storage.loadBookmarks();
    if (!mounted) return;
    setState(() {
      _bookmarks = bookmarks.reversed.toList();
      _loading = false;
    });
  }

  Future<void> _remove((int, int) bookmark) async {
    final values = await _storage.loadBookmarks();
    values.removeWhere((b) => b.$1 == bookmark.$1 && b.$2 == bookmark.$2);
    await _storage.saveBookmarks(values);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_border, size: 46, color: theme.colorScheme.primary),
                        const SizedBox(height: 14),
                        Text('No bookmarks yet', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          'Bookmark an ayah while reading and it will appear here.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                  itemCount: _bookmarks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final bookmark = _bookmarks[index];
                    final surah = bookmark.$1;
                    final ayah = bookmark.$2;
                    final arabic = quran.getVerse(surah, ayah);
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          child: Text('$ayah', style: TextStyle(color: theme.colorScheme.primary, fontSize: 11)),
                        ),
                        title: Text(quran.getSurahName(surah), style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(
                          arabic,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 16, height: 1.5, fontFamily: 'serif'),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'remove') _remove(bookmark);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'remove', child: Text('Remove bookmark')),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuranReaderScreen(surahNumber: surah, startingAyah: ayah),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
