import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_quran/app.dart';

void main() {
  testWidgets('app renders navigation', (tester) async {
    await tester.pumpWidget(const SalawatQuranApp());
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Quran'), findsOneWidget);
  });
}
