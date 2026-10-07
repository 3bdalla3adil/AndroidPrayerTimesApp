import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_quran/screens/calendar_screen.dart';

void main() {
  testWidgets('Hijri calendar renders current month and navigates', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(home: CalendarScreen()),
    );
    await tester.pump();

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('MONTH'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('Sat'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.chevron_right));
    await tester.pump();
    expect(find.text('Calendar'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pump();
    expect(find.text('Calendar'), findsOneWidget);
  });
}
