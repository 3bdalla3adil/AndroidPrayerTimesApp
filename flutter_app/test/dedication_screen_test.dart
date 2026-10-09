import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salawat_quran/screens/dedication_screen.dart';
import 'package:salawat_quran/services/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    LocaleController.locale.value = const Locale('ar');
  });

  testWidgets('dedication card shows respectful Arabic dedication', (tester) async {
    LocaleController.locale.value = const Locale('ar');
    await tester.pumpWidget(
      const CupertinoApp(home: DedicationScreen()),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('إهداء وتقدير'), findsOneWidget);
    expect(find.text('كلمات من القلب'), findsOneWidget);
    expect(find.text('إلى والد زوجتي العزيز، وأمير قلبها،'), findsOneWidget);
    expect(find.text('بكل احترام وامتنان'), findsOneWidget);
  });

  testWidgets('dedication card supports English', (tester) async {
    LocaleController.locale.value = const Locale('en');
    await tester.pumpWidget(
      const CupertinoApp(home: DedicationScreen()),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('A Gift of Gratitude'), findsOneWidget);
    expect(find.text('A Note from the Heart'), findsOneWidget);
    expect(find.text('With respect and gratitude'), findsOneWidget);
  });
}
