import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_quran/services/root_tab_navigation.dart';

void main() {
  group('RootTabNavigation', () {
    testWidgets('selectTab works from a nested route', (tester) async {
      final controller = CupertinoTabController();

      await tester.pumpWidget(
        CupertinoApp(
          home: RootTabNavigation(
            controller: controller,
            child: Navigator(
              onGenerateRoute: (_) => CupertinoPageRoute<void>(
                builder: (context) => CupertinoPageScaffold(
                  child: Center(
                    child: CupertinoButton(
                      key: const ValueKey('open-qibla'),
                      onPressed: () =>
                          RootTabNavigation.maybeOf(context)?.selectTab(3),
                      child: const Text('Open Qibla'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(controller.index, 0);
      await tester.tap(find.byKey(const ValueKey('open-qibla')));
      expect(controller.index, 3);

      await tester.pumpWidget(const CupertinoApp(home: SizedBox.shrink()));
      controller.dispose();
    });

    testWidgets('invalid tab indices are ignored', (tester) async {
      final controller = CupertinoTabController();

      await tester.pumpWidget(
        CupertinoApp(
          home: RootTabNavigation(
            controller: controller,
            child: Builder(
              builder: (context) => CupertinoPageScaffold(
                child: Center(
                  child: CupertinoButton(
                    key: const ValueKey('invalid-tab'),
                    onPressed: () =>
                        RootTabNavigation.maybeOf(context)?.selectTab(99),
                    child: const Text('Select invalid tab'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('invalid-tab')));
      expect(controller.index, 0);

      controller.dispose();
    });
  });
}
