import 'package:flutter/material.dart';
import 'package:quran_data_dart/quran.dart';
import 'quran_reader_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final controller = TextEditingController();
  List<Surah>? surahs;
  bool loading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    await QuranService.initialize();
    final data = await QuranService.getQuranData();
    if (!mounted) return;
    setState(() {
      surahs = data.surahs;
      loading = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = surahs ?? <Surah>[];
    final q = query.trim().toLowerCase();
    final filtered = all.where((s) {
      return q.isEmpty ||
          s.englishName.toLowerCase().contains(q) ||
          s.name.contains(query.trim());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SearchBar(
                    controller: controller,
                    hintText: 'Search surahs',
                    leading: const Icon(Icons.search),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final s = filtered[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          leading: CircleAvatar(child: Text(s.id.toString())),
                          title: Text(
                            s.name,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${s.englishName} • ${s.numberOfAyahs} ayat',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuranReaderScreen(surahId: s.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
