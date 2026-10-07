import 'package:flutter/cupertino.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  static const _items = <(String, String, int)>[
    ('أستغفر الله', 'Astaghfirullah', 3),
    ('سبحان الله وبحمده', 'SubhanAllahi wa bihamdihi', 10),
    ('لا إله إلا الله وحده لا شريك له', 'La ilaha illallahu wahdahu la sharika lah', 10),
    ('اللهم صل وسلم على نبينا محمد', 'Allahumma salli wa sallim ala nabiyyina Muhammad', 10),
    ('حسبي الله لا إله إلا هو عليه توكلت', 'Hasbiyallahu la ilaha illa Huwa, alayhi tawakkaltu', 7),
    ('سبحان الله والحمد لله والله أكبر', 'SubhanAllah, Alhamdulillah, Allahu Akbar', 33),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Daily Adhkar')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
          children: [
            const Text('أذكار يومية', textDirection: TextDirection.rtl, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('A small offline collection for daily remembrance.',
              textAlign: TextAlign.center, style: TextStyle(color: CupertinoColors.secondaryLabel)),
            const SizedBox(height: 18),
            for (final item in _items)
              CupertinoListSection.insetGrouped(
                children: [
                  CupertinoListTile(
                    title: Text(item.$1, textDirection: TextDirection.rtl, textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
                    subtitle: Text(item.$2 + '\nTarget: ' + item.$3.toString()),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
