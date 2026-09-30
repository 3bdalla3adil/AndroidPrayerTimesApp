import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../services/storage_service.dart';
import 'quran_reader_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  List<int> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final all = List.generate(quran.totalSurahCount, (i) => i + 1);
    if (query.isEmpty) return all;
    return all.where((number) {
      final text = '${quran.getSurahName(number)} ${quran.getSurahNameArabic(number)} ${quran.getPlaceOfRevelation(number)}';
      return text.toLowerCase().contains(query);
    }).toList();
  }

  void _openReader(int surah, {int ayah = 1}) => Navigator.push(context, MaterialPageRoute(builder: (_) => QuranReaderScreen(surahNumber: surah, startingAyah: ayah)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 110),
      children: [
        Text('THE HOLY QURAN', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.6, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
        const SizedBox(height: 7),
        Text('Read & reflect', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        Text('All 114 surahs, ready to read offline.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Find a surah',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() {}); }),
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<(int?, int?)>(
          future: StorageService().loadReaderPosition(),
          builder: (context, snapshot) {
            final surah = snapshot.data?.$1 ?? 1;
            final ayah = snapshot.data?.$2 ?? 1;
            return Card(
              color: theme.colorScheme.inverseSurface,
              child: ListTile(
                leading: Icon(Icons.bookmark_outline, color: theme.colorScheme.onInverseSurface),
                title: Text('Continue reading', style: TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.w800)),
                subtitle: Text('Verse $ayah', style: TextStyle(color: theme.colorScheme.onInverseSurface.withValues(alpha: .7))),
                trailing: Icon(Icons.arrow_outward, color: theme.colorScheme.onInverseSurface),
                onTap: () => _openReader(surah, ayah: ayah),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Text('Surahs', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
          Text('${items.length} / 114', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ]),
        const SizedBox(height: 8),
        ...items.map((number) {
          final name = quran.getSurahName(number);
          final arabic = quran.getSurahNameArabic(number);
          final place = quran.getPlaceOfRevelation(number);
          final count = quran.getVerseCount(number);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: _DiamondNumber(number: number, color: theme.colorScheme.primary),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('$place · $count verses'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(arabic, textDirection: TextDirection.rtl, style: TextStyle(color: theme.colorScheme.primary, fontSize: 17)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ]),
              onTap: () => _openReader(number),
            ),
          );
        }),
        if (items.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No surah found.'))),
      ],
    );
  }
}

class _DiamondNumber extends StatelessWidget {
  const _DiamondNumber({required this.number, required this.color});
  final int number;
  final Color color;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: 0.785398,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: .2)), borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Transform.rotate(angle: -0.785398, child: Text(number.toString(), style: TextStyle(color: color, fontWeight: FontWeight.w800))),
    ),
  );
}
