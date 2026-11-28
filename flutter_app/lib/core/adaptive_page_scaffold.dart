import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;

import '../theme/app_theme.dart';
import '../theme/islamic_page_background.dart';

/// Platform-aware page shell. iOS keeps native Cupertino navigation; Android
/// gets a Material Scaffold. Both share the same page surface and subtle
/// Islamic geometric background treatment.
class AdaptivePageScaffold extends StatelessWidget {
  const AdaptivePageScaffold({
    super.key,
    required this.child,
    this.navigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget child;
  final Widget? navigationBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  Widget _materializeNavigationAction(Widget? action) {
    if (action is CupertinoButton) {
      final child = action.child;
      if (child is Icon) {
        return material.IconButton(
          key: action.key,
          onPressed: action.onPressed,
          padding: action.padding,
          icon: child,
        );
      }
      final style = action.color == null
          ? null
          : material.ButtonStyle(
              backgroundColor:
                  material.WidgetStatePropertyAll<Color?>(action.color),
            );
      return action.color == null
          ? material.TextButton(
              key: action.key,
              onPressed: action.onPressed,
              style: style,
              child: child,
            )
          : material.FilledButton(
              key: action.key,
              onPressed: action.onPressed,
              style: style,
              child: child,
            );
    }
    return action ?? const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final pageBackground = backgroundColor ??
        (isDark ? AppTheme.midnightGreen : const Color(0xFFF5F2E9));
    final pageContent = IslamicPageBackground(child: child);

    if (_isIOS) {
      return CupertinoPageScaffold(
        navigationBar: navigationBar is ObstructingPreferredSizeWidget
            ? navigationBar as ObstructingPreferredSizeWidget
            : null,
        backgroundColor: pageBackground,
        child: pageContent,
      );
    }

    final bar = navigationBar;
    material.PreferredSizeWidget? appBar;
    if (bar is CupertinoNavigationBar) {
      appBar = material.AppBar(
        key: bar.key,
        title: bar.middle,
        leading: bar.leading == null
            ? null
            : _materializeNavigationAction(bar.leading),
        automaticallyImplyLeading: bar.automaticallyImplyLeading,
        actions: bar.trailing == null
            ? null
            : <Widget>[_materializeNavigationAction(bar.trailing)],
        backgroundColor: bar.backgroundColor ?? backgroundColor,
      );
    } else if (bar is material.PreferredSizeWidget) {
      appBar = bar;
    }

    return material.Scaffold(
      appBar: appBar,
      backgroundColor: pageBackground,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: pageContent,
    );
  }
}
