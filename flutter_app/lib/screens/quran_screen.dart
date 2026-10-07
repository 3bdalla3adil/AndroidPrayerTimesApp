import 'package:flutter/cupertino.dart';
import 'package:quran/quran.dart' as quran;

import 'quran_reader_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  String _query = '';

  List<int> get _items {
    final query = _query.trim().toLowerCase();
    final all = List.generate(quran.totalSurahCount, (i) => i + 1);
    if (query.isEmpty) return all;
    return all.where((number) {
      final text = quran.getSurahName(number) + ' ' + quran.getSurahNameArabic(number);
      return text.toLowerCase().contains(query) || number.toString() == query;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('القرآن الكريم')),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  CupertinoSearchTextField(
                    placeholder: 'Search surah',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  CupertinoListSection.insetGrouped(
                    children: [
                      for (final number in items)
                        CupertinoListTile(
                          leading: _NumberBadge(number: number),
                          title: Text(quran.getSurahName(number)),
                          subtitle: Text(
                            quran.getPlaceOfRevelation(number) +
                                ' • ' +
                                quran.getVerseCount(number).toString() +
                                ' verses',
                          ),
                          trailing: Text(
                            quran.getSurahNameArabic(number),
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontFamily: 'serif', fontSize: 17),
                          ),
                          onTap: () => Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => QuranReaderScreen(surahNumber: number),
                            ),
                          ),
                        ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CupertinoColors.activeGreen.resolveFrom(context),
        ),
        alignment: Alignment.center,
        child: Text(
          number.toString(),
          style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w700),
        ),
      );
}
