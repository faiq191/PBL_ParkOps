import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_parkops/features/parking/data/camera_feeds.dart';

void main() {
  test('configures all three selectable camera feeds', () {
    expect(cameraFeeds.map((feed) => feed.id), [
      'opentopia-17916',
      'opentopia-17921',
      'opentopia-17917',
    ]);
    expect(cameraFeeds.map((feed) => feed.pageUri.host), [
      'www.opentopia.com',
      'www.opentopia.com',
      'www.opentopia.com',
    ]);
  });
}
