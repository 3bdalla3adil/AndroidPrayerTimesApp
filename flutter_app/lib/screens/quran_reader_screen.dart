import 'package:flutter/material.dart';
import 'package:quran_data_dart/quran.dart';
import '../services/storage_service.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key, required this.surahId});
  final int surahId;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  Surah? surah;
  double fontSize = 26;
  final storage = StorageService();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    fontSize = await storage.loadQuranFontSize();
    final value = await QuranService.getSurah(widget.surahId);
    if (!mounted) return;
    setState(() => surah = value);
  }

  Future<void> setFont(double value) async {
    setState(() => fontSize = value);
    await storage.saveQuranFontSize(value);
  }

  @override
  Widget build(BuildContext context) {
    final s = surah;
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.name ?? 'القرآن الكريم'),
        actions: [
          IconButton(
            onPressed: () => setFont((fontSize - 2).clamp(20, 36).toDouble()),
            icon: const Icon(Icons.text_decrease),
          ),
          IconButton(
            onPressed: () => setFont((fontSize + 2).clamp(20, 36).toDouble()),
            icon: const Icon(Icons.text_increase),
          ),
        ],
      ),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF15110B)
                  : const Color(0xFFFFFCF3),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          s.name,
                          textDirection: TextDirection.rtl,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text('${s.englishName} • ${s.numberOfAyahs} ayat'),
                        if (widget.surahId != 9) ...[
                          const SizedBox(height: 22),
                          const Text(
                            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 23, height: 1.8),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...s.ayat.map(
                    (ayah) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => storage.saveReaderPosition(widget.surahId, ayah.id),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: RichText(
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.justify,
                            text: TextSpan(
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: fontSize,
                                height: 2.05,
                              ),
                              children: [
                                TextSpan(text: ayah.text),
                                TextSpan(
                                  text: '  ﴿${ayah.id}﴾',
                                  style: TextStyle(
                                    fontSize: fontSize * .72,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
