import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/screens/quran_reader_screen.dart';
import 'package:salawat_quran/services/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    LocaleController.locale.value = const Locale('ar');
  });

  testWidgets('Quran reader scrolls continuously without nested vertical scrollers',
      (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(home: QuranReaderScreen(surahNumber: 1)),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    final listFinder = find.byType(ListView);
    expect(listFinder, findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);

    final controller = tester.widget<ListView>(listFinder).controller!;
    await tester.drag(listFinder, const Offset(0, -900));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(controller.offset, greaterThan(0));
  });
}
