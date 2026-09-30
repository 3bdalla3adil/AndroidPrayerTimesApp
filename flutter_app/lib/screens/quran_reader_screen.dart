import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;

import '../services/storage_service.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key, required this.surahNumber, this.startingAyah = 1});
  final int surahNumber;
  final int startingAyah;
  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final _player = AudioPlayer();
  final _storage = StorageService();
  double _fontSize = 28;
  bool _showTranslation = true;
  int? _playingAyah;
  final Set<String> _bookmarked = {};

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final saved = await _storage.loadQuranFontSize();
    final bookmarks = await _storage.loadBookmarks();
    if (!mounted) return;
    setState(() {
      _fontSize = saved;
      _bookmarked.addAll(bookmarks.where((b) => b.$1 == widget.surahNumber).map((b) => b.$2.toString()));
    });
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  int _globalAyahNumber(int surah, int ayah) {
    var total = 0;
    for (var i = 1; i < surah; i++) total += quran.getVerseCount(i);
    return total + ayah;
  }

  Future<void> _toggleAudio(int ayah) async {
    final global = _globalAyahNumber(widget.surahNumber, ayah);
    final url = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/' + global.toString() + '.mp3';
    try {
      if (_playingAyah == ayah && _player.playing) {
        await _player.pause();
        if (mounted) setState(() => _playingAyah = null);
        return;
      }
      await _player.setUrl(url);
      if (mounted) setState(() => _playingAyah = ayah);
      await _player.play();
      if (mounted) setState(() => _playingAyah = null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingAyah = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio could not be started. Check your connection.')));
    }
  }

  Future<void> _toggleBookmark(int ayah) async {
    final bookmarks = await _storage.loadBookmarks();
    final exists = bookmarks.any((b) => b.$1 == widget.surahNumber && b.$2 == ayah);
    if (exists) {
      bookmarks.removeWhere((b) => b.$1 == widget.surahNumber && b.$2 == ayah);
    } else {
      bookmarks.add((widget.surahNumber, ayah));
    }
    await _storage.saveBookmarks(bookmarks);
    if (mounted) setState(() => exists ? _bookmarked.remove(ayah.toString()) : _bookmarked.add(ayah.toString()));
  }

  Future<void> _savePosition(int ayah) => _storage.saveReaderPosition(widget.surahNumber, ayah);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = quran.getSurahName(widget.surahNumber);
    final arabicName = quran.getSurahNameArabic(widget.surahNumber);
    final count = quran.getVerseCount(widget.surahNumber);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text(arabicName, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 12)),
        ]),
        actions: [
          IconButton(onPressed: () => setState(() => _showTranslation = !_showTranslation), icon: Icon(_showTranslation ? Icons.translate : Icons.translate_outlined)),
          IconButton(onPressed: _fontSize <= 24 ? null : () { setState(() => _fontSize = math.max(24, _fontSize - 2)); _storage.saveQuranFontSize(_fontSize); }, icon: const Icon(Icons.text_decrease)),
          IconButton(onPressed: _fontSize >= 42 ? null : () { setState(() => _fontSize = math.min(42, _fontSize + 2)); _storage.saveQuranFontSize(_fontSize); }, icon: const Icon(Icons.text_increase)),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
        itemCount: count + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                decoration: BoxDecoration(color: theme.colorScheme.inverseSurface, borderRadius: BorderRadius.circular(22)),
                child: Column(children: [
                  Text('THE HOLY QURAN · ' + count.toString() + ' VERSES', style: TextStyle(color: theme.colorScheme.onInverseSurface.withOpacity(.7), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                  const SizedBox(height: 9),
                  Text(arabicName, textDirection: TextDirection.rtl, style: TextStyle(color: theme.colorScheme.onInverseSurface, fontSize: 31, height: 1.4, fontFamily: 'serif')),
                  Text(name, style: TextStyle(color: theme.colorScheme.onInverseSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(quran.getPlaceOfRevelation(widget.surahNumber), style: TextStyle(color: theme.colorScheme.onInverseSurface.withOpacity(.7), fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 14),
              Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', textDirection: TextDirection.rtl, style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontFamily: 'serif')),
              const SizedBox(height: 16),
            ]);
          }
          final ayah = index;
          final arabic = quran.getVerse(widget.surahNumber, ayah);
          final translation = quran.getVerseTranslation(widget.surahNumber, ayah);
          final active = _playingAyah == ayah;
          final bookmarked = _bookmarked.contains(ayah.toString());
          return GestureDetector(
            onTap: () => _savePosition(ayah),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  CircleAvatar(radius: 15, backgroundColor: theme.colorScheme.secondaryContainer, child: Text(ayah.toString(), style: TextStyle(fontSize: 11, color: theme.colorScheme.primary))),
                  const Spacer(),
                  IconButton(onPressed: () => _toggleAudio(ayah), icon: Icon(active ? Icons.pause_circle_filled : Icons.play_circle_outline, color: theme.colorScheme.primary)),
                  IconButton(onPressed: () => _toggleBookmark(ayah), icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_outline, color: bookmarked ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant)),
                ]),
                const SizedBox(height: 4),
                Text(arabic, textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: TextStyle(fontSize: _fontSize, height: 1.95, fontFamily: 'serif')),
                if (_showTranslation) ...[
                  const SizedBox(height: 9),
                  Text(translation, style: TextStyle(fontSize: 14, height: 1.55, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }
}
