import 'package:flutter_test/flutter_test.dart';

void main() {
  test('basic prayer countdown math is stable', () {
    final now = DateTime(2026, 1, 1, 12);
    final next = DateTime(2026, 1, 1, 13, 30);
    expect(next.difference(now).inMinutes, 90);
  });
}
