import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../lib/core/adaptive_controls.dart';

void main() {
  testWidgets('Android renders Material 3 controls', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
      const material.MaterialApp(
        home: material.Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                AdaptiveListSection.insetGrouped(
                  header: Text('SETTINGS'),
                  children: [
                    AdaptiveListTile(
                      leading: Icon(material.Icons.notifications),
                      title: Text('Notifications'),
                    ),
                  ],
                ),
                AdaptiveSwitch(value: true, onChanged: null),
                AdaptiveActivityIndicator(),
                AdaptiveAlertDialog(
                  title: Text('Confirm'),
                  content: Text('Continue?'),
                  actions: [
                    AdaptiveDialogAction(
                      isDefaultAction: true,
                      onPressed: null,
                      child: Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(material.Card), findsOneWidget);
    expect(find.byType(material.ListTile), findsOneWidget);
    expect(find.byType(material.Switch), findsOneWidget);
    expect(find.byType(material.CircularProgressIndicator), findsOneWidget);
    expect(find.byType(material.AlertDialog), findsOneWidget);
    expect(find.byType(CupertinoListTile), findsNothing);
      expect(find.byType(CupertinoSwitch), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS keeps native Cupertino controls', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: SingleChildScrollView(
            child: Column(
              children: [
                AdaptiveListSection.insetGrouped(
                  header: Text('SETTINGS'),
                  children: [
                    AdaptiveListTile(
                      leading: Icon(CupertinoIcons.bell),
                      title: Text('Notifications'),
                    ),
                  ],
                ),
                AdaptiveSwitch(value: true, onChanged: null),
                AdaptiveActivityIndicator(),
                AdaptiveAlertDialog(
                  title: Text('Confirm'),
                  content: Text('Continue?'),
                  actions: [
                    AdaptiveDialogAction(
                      isDefaultAction: true,
                      onPressed: null,
                      child: Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoListTile), findsOneWidget);
    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.byType(material.ListTile), findsNothing);
      expect(find.byType(material.Switch), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
