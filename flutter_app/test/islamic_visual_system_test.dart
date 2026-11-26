import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salawat_quran/theme/app_theme.dart';
import 'package:salawat_quran/theme/islamic_page_background.dart';

void main() {
  group('Islamic visual system', () {
    test('uses the shared emerald and antique-gold palette', () {
      final theme = AppTheme.materialData;
      expect(theme.colorScheme.primary, AppTheme.deepEmerald);
      expect(theme.colorScheme.secondary, AppTheme.antiqueGold);
      expect(theme.iconTheme.color, AppTheme.deepEmerald);
    });

    test('shares layout, typography, and dark-mode tokens', () {
      expect(AppTheme.screenPadding, const EdgeInsets.all(16));
      expect(AppTheme.radiusCard, 20);
      expect(AppTheme.radiusControl, 14);
      expect(AppTheme.data.primaryColor, AppTheme.emerald);
      expect(AppTheme.materialDarkData.colorScheme.surface, AppTheme.darkSurface);
      expect(AppTheme.materialData.filledButtonTheme.style, isNotNull);
      expect(AppTheme.materialData.inputDecorationTheme.filled, isTrue);
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
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });
  });
}
