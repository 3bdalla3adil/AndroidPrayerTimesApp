import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart'
import 'package:salawat_quran/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock the NEW async SharedPreferences API.
    // SharedPreferences.setMockInitialValues only covers the legacy API.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('app renders navigation', (tester) async {
    await tester.pumpWidget(const SalawatQuranApp());

    // Two frames is enough. Do NOT use pumpAndSettle — HomeScreen has a
    // Timer.periodic(1s) that would make it time out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Quran'), findsOneWidget);
  });
}
