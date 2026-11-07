import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_quran/services/notification_service.dart';

void main() {
  group('NotificationService sound selection', () {
    test('uses the dedicated Madinah Fajr sound for Fajr', () {
      expect(
        NotificationService.soundForPrayer('Fajr', 'dubai'),
        'fajr_madinah',
      );
      expect(
        NotificationService.soundForPrayer('fajr', 'default'),
        'fajr_madinah',
      );
    });

    test('uses the selected sound for other prayers', () {
      for (final prayer in ['Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        expect(
          NotificationService.soundForPrayer(prayer, 'madinah'),
          'madinah',
        );
      }
    });

    test('exposes only bundled sound resources', () {
      expect(
        NotificationService.soundResources.keys.toSet(),
        NotificationService.soundLabels.keys.toSet(),
      );
      expect(NotificationService.soundResources.values.toSet(), {
        'azan',
        'azan_madinah',
        'azan_dubai',
        'azan_fajr_madinah',
      });
    });
  });
}
