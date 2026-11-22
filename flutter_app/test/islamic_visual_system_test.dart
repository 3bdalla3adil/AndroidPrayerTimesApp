import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/theme/app_theme.dart';
import '../lib/theme/islamic_page_background.dart';

void main() {
  group('Islamic visual system', () {
    test('uses the shared emerald and antique-gold palette', () {
      final theme = AppTheme.materialData;
      expect(theme.colorScheme.primary, AppTheme.deepEmerald);
      expect(theme.colorScheme.secondary, AppTheme.antiqueGold);
      expect(theme.iconTheme.color, AppTheme.deepEmerald);
    });

    testWidgets('page background paints a decorative layer behind content',
        (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: IslamicPageBackground(
            child: Center(child: Text('Salawat')),
          ),
        ),
      );

      expect(find.text('Salawat'), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });
}
