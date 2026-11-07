import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_parkops/features/parking/data/models/camera_inference_result_model.dart';

void main() {
  test('maps the latest inference document to a camera result', () {
    final processedAt = DateTime.utc(2026, 11, 7, 5);
    final result = CameraInferenceResultModel.fromFirestore('opentopia-17916', {
      'vehicleCount': 3,
      'emptySpaceCount': 5,
      'processedAt': Timestamp.fromDate(processedAt),
      'frameWidth': 640,
      'frameHeight': 480,
      'framePreview': Blob(Uint8List.fromList([1, 2, 3])),
      'detections': [
        {
          'className': 'busy',
          'confidence': 0.93,
          'box': [10, 20, 100, 200],
        },
      ],
    }).toEntity();

    expect(result.cameraId, 'opentopia-17916');
    expect(result.vehicleCount, 3);
    expect(result.emptySpaceCount, 5);
    expect(result.processedAt!.isAtSameMomentAs(processedAt), isTrue);
    expect(result.frameWidth, 640);
    expect(result.frameHeight, 480);
    expect(result.framePreview, [1, 2, 3]);
    expect(result.detections, hasLength(1));
    expect(result.detections.single.className, 'busy');
    expect(result.detections.single.confidence, 0.93);
    expect(result.detections.single.box, [10, 20, 100, 200]);
  });
}
