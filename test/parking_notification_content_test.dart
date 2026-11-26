import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_parkops/features/parking/data/camera_feeds.dart';
import 'package:pbl_parkops/features/parking/data/seed_zones.dart';
import 'package:pbl_parkops/features/parking/domain/entities/camera_inference_result.dart';
import 'package:pbl_parkops/features/settings/data/parking_notification_content.dart';
import 'package:pbl_parkops/features/settings/data/parking_notification_service.dart';

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

  test('live summary uses ML counts instead of seeded demo availability', () {
    final content = buildSummaryContent(
      results: [
        _mlResult(cameraFeeds[0].id, vehicles: 3, emptySpaces: 7),
        _mlResult(cameraFeeds[1].id, vehicles: 5, emptySpaces: 2),
      ],
      favoriteLotName: 'Graha Polinema',
    );

    expect(content.title, '9 spaces detected by parking cameras');
    expect(
      content.body,
      contains('Graha Polinema · '
          '${cameraFeeds[0].title}: 7 empty · '
          '${cameraFeeds[1].title}: 2 empty · '
          '8 vehicles detected'),
    );
    // The seeded numbers (18 / 4 / 0) must not leak into the notification.
    expect(content.body, isNot(contains('18 available')));
  });

  test('live summary omits the favorite label when it is unavailable', () {
    final content = buildSummaryContent(
      results: [_mlResult(cameraFeeds[0].id, vehicles: 1, emptySpaces: 1)],
      favoriteLotName: null,
    );

    expect(content.title, '1 space detected by parking cameras');
    expect(content.body, isNot(contains('Graha Polinema')));
    expect(content.body, contains('1 vehicle detected'));
  });
}

CameraInferenceResult _mlResult(
  String cameraId, {
  required int vehicles,
  required int emptySpaces,
}) {
  return CameraInferenceResult(
    cameraId: cameraId,
    vehicleCount: vehicles,
    emptySpaceCount: emptySpaces,
    processedAt: DateTime(2026, 11, 18, 8, 30),
    detections: const [],
    frameWidth: 640,
    frameHeight: 480,
    framePreview: null,
  );
}
