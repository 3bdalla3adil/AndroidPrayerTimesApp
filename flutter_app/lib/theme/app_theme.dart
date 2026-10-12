import 'package:flutter/cupertino.dart';

/// Shared Salawat brand palette, sampled from the supplied app icon:
/// midnight green, deep emerald, soft mint, warm ivory and antique gold.
/// Dynamic surfaces preserve a comfortable contrast in both system themes.
class AppTheme {
  const AppTheme._();

  static const midnightGreen = Color(0xFF071F1A);
  static const deepEmerald = Color(0xFF104B3D);
  static const emerald = Color(0xFF176B52);
  static const softMint = Color(0xFFE8F3ED);
  static const antiqueGold = Color(0xFFC7A45A);
  static const warmIvory = Color(0xFFFAF8F1);
  static const darkSurface = Color(0xFF102B24);
  static const darkCard = Color(0xFF15372E);

  static const groupedBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF5F3EA),
    darkColor: midnightGreen,
  );
  static const barBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFDF7),
    darkColor: darkSurface,
  );
  static const cardBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: darkCard,
  );
  static const subtleAccent = CupertinoDynamicColor.withBrightness(
    color: softMint,
    darkColor: deepEmerald,
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
            height: 1.35,
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
