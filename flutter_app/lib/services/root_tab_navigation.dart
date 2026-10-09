import 'package:flutter/cupertino.dart';

/// Exposes the root tab controller to screens that offer shortcuts to
/// top-level destinations. This avoids pushing duplicate copies of tab screens.
class RootTabNavigation extends InheritedWidget {
  const RootTabNavigation({
    required this.controller,
    required super.child,
    super.key,
  });

  final CupertinoTabController controller;

  void selectTab(int index) {
    if (index >= 0 && index < 5) {
      controller.index = index;
    }
  }

  static RootTabNavigation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RootTabNavigation>();

  @override
  bool updateShouldNotify(RootTabNavigation oldWidget) =>
      controller != oldWidget.controller;
}
