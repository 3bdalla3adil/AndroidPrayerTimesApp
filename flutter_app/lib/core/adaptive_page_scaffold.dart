import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;

/// Platform-aware page shell. iOS keeps native Cupertino navigation; Android
/// gets a Material Scaffold and AppBar while preserving each screen's content.
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

  @override
  Widget build(BuildContext context) {
    if (_isIOS) {
      return CupertinoPageScaffold(
        navigationBar: navigationBar is ObstructingPreferredSizeWidget
            ? navigationBar as ObstructingPreferredSizeWidget
            : null,
        backgroundColor: backgroundColor,
        child: child,
      );
    }

    final bar = navigationBar;
    material.PreferredSizeWidget? appBar;
    if (bar is CupertinoNavigationBar) {
      appBar = material.AppBar(
        key: bar.key,
        title: bar.middle,
        leading: bar.leading,
        automaticallyImplyLeading: bar.automaticallyImplyLeading,
        actions: bar.trailing == null ? null : <Widget>[bar.trailing!],
        backgroundColor: backgroundColor,
      );
    } else if (bar is material.PreferredSizeWidget) {
      appBar = bar;
    }

    return material.Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor ?? const Color(0xFFF5F3EA),
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: child,
    );
  }
}
