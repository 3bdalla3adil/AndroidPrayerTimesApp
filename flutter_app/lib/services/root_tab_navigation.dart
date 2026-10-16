import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// Shares tab selection with shortcuts without creating duplicate tab routes.
class RootTabNavigation extends InheritedWidget {
  const RootTabNavigation({
    required this.controller,
    required this.materialIndex,
    required super.child,
    super.key,
  });

  final CupertinoTabController controller;
  final ValueNotifier<int> materialIndex;

  void selectTab(int index) {
    if (index < 0 || index >= 5) return;
    controller.index = index;
    materialIndex.value = index;
  }

  static RootTabNavigation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RootTabNavigation>();

  @override
  bool updateShouldNotify(RootTabNavigation oldWidget) =>
      controller != oldWidget.controller || materialIndex != oldWidget.materialIndex;
}
