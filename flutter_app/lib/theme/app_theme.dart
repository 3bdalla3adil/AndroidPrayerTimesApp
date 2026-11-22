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
      );

  static CupertinoThemeData get data => const CupertinoThemeData(
        primaryColor: emerald,
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
