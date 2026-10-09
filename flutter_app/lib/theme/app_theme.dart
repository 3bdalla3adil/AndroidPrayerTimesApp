import 'package:flutter/cupertino.dart';

/// Shared visual language for Salawat: deep emerald, warm ivory and subtle gold.
/// Cupertino's dynamic system colors keep controls readable in light and dark mode,
/// while the Quran reader retains its traditional Mushaf paper treatment.
class AppTheme {
  const AppTheme._();

  static const emerald = Color(0xFF176B52);
  static const deepEmerald = Color(0xFF104B3D);
  static const softMint = Color(0xFFE8F3ED);
  static const antiqueGold = Color(0xFFC7A45A);
  static const warmIvory = Color(0xFFFAF8F1);

  static CupertinoThemeData get data => const CupertinoThemeData(
        primaryColor: emerald,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        barBackgroundColor: CupertinoColors.systemBackground,
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
