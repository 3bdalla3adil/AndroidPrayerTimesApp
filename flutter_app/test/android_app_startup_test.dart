import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/app.dart';
import 'package:salawat_quran/services/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    LocaleController.locale.value = const Locale('ar');
  });

  testWidgets(
    'Android cold start renders Material UI and opens Home without exceptions',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(const SalawatQuranApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(material.MaterialApp), findsOneWidget);
        expect(find.byType(CupertinoApp), findsNothing);
        expect(find.text('إهداء وتقدير'), findsOneWidget);
        expect(find.text('الدخول إلى التطبيق'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('الدخول إلى التطبيق'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('السلام عليكم'), findsOneWidget);
        expect(find.byType(material.Scaffold), findsWidgets);
        expect(find.byType(CupertinoPageScaffold), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'Android navigation opens More and Qibla and returns without exceptions',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(const SalawatQuranApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('الدخول إلى التطبيق'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const ValueKey('open-more')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('العلامات المرجعية'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('القبلة'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('اتجاه القبلة'), findsWidgets);
        expect(tester.takeException(), isNull);

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('العلامات المرجعية'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
