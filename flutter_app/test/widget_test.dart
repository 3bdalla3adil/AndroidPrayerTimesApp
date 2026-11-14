import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('app has no bottom bar and named routes work from Home and More',
      (tester) async {
    await tester.pumpWidget(const SalawatQuranApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Dismiss the app's first-run dedication before interacting with Home.
    expect(find.text('الدخول إلى التطبيق'), findsOneWidget);
    await tester.tap(find.text('الدخول إلى التطبيق'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('السلام عليكم'), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsNothing);
    expect(find.byType(material.NavigationBar), findsNothing);
    expect(find.byType(material.BottomNavigationBar), findsNothing);

    // Home -> More -> Qibla must use the root named-route navigator.
    await tester.tap(find.byKey(const ValueKey('open-more')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('العلامات المرجعية'), findsOneWidget);

    await tester.tap(find.text('القبلة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('اتجاه القبلة'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('العلامات المرجعية'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('السلام عليكم'), findsOneWidget);
  });
}
