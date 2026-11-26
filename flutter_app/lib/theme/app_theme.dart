import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;

/// Shared Salawat visual system: deep emerald, warm parchment and restrained
/// antique gold. The palette is intentionally calm and high-contrast rather
/// than relying on bright gradients or decorative UI everywhere.
class AppTheme {
  const AppTheme._();

  static const midnightGreen = Color(0xFF071F1A);
  static const deepEmerald = Color(0xFF104B3D);
  static const emerald = Color(0xFF176B52);
  static const emeraldLight = Color(0xFF2E8065);
  static const softMint = Color(0xFFE8F3ED);
  static const antiqueGold = Color(0xFFC7A45A);
  static const warmIvory = Color(0xFFFAF8F1);
  static const parchment = Color(0xFFF2EBDD);
  static const darkSurface = Color(0xFF102B24);
  static const darkCard = Color(0xFF15372E);
  static const darkText = Color(0xFFF4F0E5);

  // Shared layout scale. Screens should use these values instead of inventing
  // local spacing and corner radii.
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 20.0;
  static const space6 = 24.0;
  static const space7 = 32.0;

  static const radiusSmall = 12.0;
  static const radiusControl = 14.0;
  static const radiusCard = 20.0;
  static const radiusHero = 28.0;

  static const screenPadding = EdgeInsets.all(space4);
  static const sectionSpacing = SizedBox(height: space6);
  static const cardPadding = EdgeInsets.all(space4);

  static const headingStyle = TextStyle(
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: midnightGreen,
  );
  static const bodyStyle = TextStyle(
    fontSize: 16,
    height: 1.5,
    color: midnightGreen,
  );
  static const supportingStyle = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: Color(0xFF68756E),
  );

  static const groupedBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF5F2E9),
    darkColor: midnightGreen,
  );
  static const barBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFCFAF4),
    darkColor: darkSurface,
  );
  static const cardBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFEFA),
    darkColor: darkCard,
  );
  static const subtleAccent = CupertinoDynamicColor.withBrightness(
    color: softMint,
    darkColor: deepEmerald,
  );
  static const iconTint = CupertinoDynamicColor.withBrightness(
    color: deepEmerald,
    darkColor: Color(0xFFD8C18A),
  );
  static const mutedText = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF68756E),
    darkColor: Color(0xFFB8C6BE),
  );

  static material.ThemeData get materialData => material.ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: groupedBackground,
        colorScheme: material.ColorScheme.fromSeed(
          seedColor: deepEmerald,
          brightness: material.Brightness.light,
          primary: deepEmerald,
          onPrimary: warmIvory,
          secondary: antiqueGold,
          onSecondary: midnightGreen,
          surface: warmIvory,
          onSurface: midnightGreen,
        ),
        visualDensity: material.VisualDensity.standard,
        textTheme: const material.TextTheme(
          headlineSmall: headingStyle,
          titleLarge: TextStyle(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: midnightGreen,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: midnightGreen,
          ),
          bodyLarge: bodyStyle,
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: midnightGreen,
          ),
          bodySmall: supportingStyle,
        ),
        iconTheme: const material.IconThemeData(color: deepEmerald, size: 22),
        primaryIconTheme: const material.IconThemeData(color: warmIvory, size: 22),
        appBarTheme: const material.AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: barBackground,
          foregroundColor: midnightGreen,
          surfaceTintColor: material.Colors.transparent,
        ),
        cardTheme: material.CardThemeData(
          color: cardBackground,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0x1A176B52)),
          ),
        ),
        listTileTheme: const material.ListTileThemeData(
          iconColor: deepEmerald,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          minLeadingWidth: 28,
        ),
        navigationBarTheme: const material.NavigationBarThemeData(
          backgroundColor: barBackground,
          indicatorColor: softMint,
          labelBehavior: material.NavigationDestinationLabelBehavior.alwaysShow,
        ),
        dividerTheme: const material.DividerThemeData(
          color: Color(0x1F176B52),
          thickness: 0.7,
          space: 1,
        ),
        inputDecorationTheme: material.InputDecorationTheme(
          filled: true,
          fillColor: cardBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: space4,
            vertical: space3,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusControl),
            borderSide: const BorderSide(color: Color(0x33176B52)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusControl),
            borderSide: const BorderSide(color: Color(0x33176B52)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusControl),
            borderSide: const BorderSide(color: deepEmerald, width: 1.5),
          ),
        ),
        outlinedButtonTheme: material.OutlinedButtonThemeData(
          style: material.OutlinedButton.styleFrom(
            foregroundColor: deepEmerald,
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: Color(0x55176B52)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusControl),
            ),
          ),
        ),
        textButtonTheme: material.TextButtonThemeData(
          style: material.TextButton.styleFrom(
            foregroundColor: deepEmerald,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusControl),
            ),
          ),
        ),
        filledButtonTheme: material.FilledButtonThemeData(
          style: material.FilledButton.styleFrom(
            backgroundColor: deepEmerald,
            foregroundColor: warmIvory,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  static material.ThemeData get materialDarkData => material.ThemeData(
        useMaterial3: true,
        brightness: material.Brightness.dark,
        scaffoldBackgroundColor: midnightGreen,
        colorScheme: material.ColorScheme.fromSeed(
          seedColor: emeraldLight,
          brightness: material.Brightness.dark,
          primary: const Color(0xFF9AD8BC),
          onPrimary: midnightGreen,
          secondary: const Color(0xFFD8BC78),
          onSecondary: midnightGreen,
          surface: darkSurface,
          onSurface: darkText,
        ),
        textTheme: const material.TextTheme(
          headlineSmall: TextStyle(
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
          bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: darkText),
          bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: darkText),
          bodySmall: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Color(0xFFB8C6BE),
          ),
        ),
        iconTheme: const material.IconThemeData(
          color: Color(0xFFD8C18A),
          size: 22,
        ),
        appBarTheme: const material.AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: darkSurface,
          foregroundColor: darkText,
          surfaceTintColor: material.Colors.transparent,
        ),
        cardTheme: material.CardThemeData(
          color: darkCard,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0x26D8C18A)),
          ),
        ),
        listTileTheme: const material.ListTileThemeData(
          iconColor: Color(0xFFD8C18A),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          minLeadingWidth: 28,
        ),
        navigationBarTheme: const material.NavigationBarThemeData(
          backgroundColor: darkSurface,
          indicatorColor: deepEmerald,
          labelBehavior: material.NavigationDestinationLabelBehavior.alwaysShow,
        ),
        dividerTheme: const material.DividerThemeData(
          color: Color(0x26D8C18A),
          thickness: 0.7,
          space: 1,
        ),
        inputDecorationTheme: material.InputDecorationTheme(
          filled: true,
          fillColor: darkCard,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: space4,
            vertical: space3,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusControl),
            borderSide: const BorderSide(color: Color(0x55D8C18A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusControl),
            borderSide: const BorderSide(color: Color(0x55D8C18A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusControl),
            borderSide: const BorderSide(color: Color(0xFFD8C18A), width: 1.5),
          ),
        ),
        outlinedButtonTheme: material.OutlinedButtonThemeData(
          style: material.OutlinedButton.styleFrom(
            foregroundColor: Color(0xFFD8C18A),
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: Color(0x55D8C18A)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusControl),
            ),
          ),
        ),
        textButtonTheme: material.TextButtonThemeData(
          style: material.TextButton.styleFrom(
            foregroundColor: Color(0xFFD8C18A),
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusControl),
            ),
          ),
        ),
      );

  static CupertinoThemeData get data => const CupertinoThemeData(
        primaryColor: emerald,
        primaryContrastingColor: warmIvory,
        scaffoldBackgroundColor: groupedBackground,
        barBackgroundColor: barBackground,
        textTheme: CupertinoTextThemeData(
          primaryColor: emerald,
          textStyle: TextStyle(
            fontSize: 16,
            color: CupertinoColors.label,
            height: 1.45,
          ),
          navTitleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.label,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.label,
          ),
          actionTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: emerald,
          ),
          tabLabelTextStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      );
}
