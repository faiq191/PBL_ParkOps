import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_parkops/features/parking/data/seed_zones.dart';
import 'package:pbl_parkops/features/settings/data/parking_notification_content.dart';

void main() {
  test('daily summary includes favorite lot count and every lot count', () {
    final content = ParkingNotificationContent.fromZones(
      zones: seedZones,
      favoriteLotId: 'lot1',
    );

    expect(content.title, '18 spaces available at Graha Polinema');
    expect(
      content.body,
      'Graha Polinema: 18 available · North Lot: 4 available · '
      'South Lot: 0 available',
    );
  });

  test('daily summary rejects a favorite lot that is not in the data', () {
    expect(
      () => ParkingNotificationContent.fromZones(
        zones: seedZones,
        favoriteLotId: 'missing-lot',
      ),
      throwsArgumentError,
    );
  });
}
