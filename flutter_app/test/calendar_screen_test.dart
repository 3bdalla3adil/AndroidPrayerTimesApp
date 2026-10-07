import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_quran/screens/calendar_screen.dart';

void main() {
  testWidgets('Hijri calendar renders current month and navigates', (tester) async {
    await tester.pumpWidget(const CalendarScreen());
    await tester.pump();

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('MONTH'), findsOneWidget);
    expect(find.text('CALENDAR ACCURACY'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pump();

    expect(find.text('Calendar'), findsOneWidget);
  });
}
