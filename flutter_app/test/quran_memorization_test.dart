import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/screens/quran_memorization_screen.dart';
import 'package:salawat_quran/services/locale_controller.dart';
import 'package:salawat_quran/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    LocaleController.locale.value = const Locale('ar');
  });

  testWidgets('memorization screen reveals ayah and saves mastered progress', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuranMemorizationScreen()));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('حفظ القرآن'), findsOneWidget);
    expect(find.text('إظهار الآية'), findsOneWidget);

    await tester.tap(find.text('إظهار الآية'));
    await tester.pump();
    expect(find.text('إخفاء الآية'), findsOneWidget);

    await tester.tap(find.text('حفظت الآية'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final storage = StorageService();
    expect((await storage.loadMemorizedAyahs()).contains('1:1'), isTrue);
    expect((await storage.loadMemorizationSession())['current'], 2);
  });
}
