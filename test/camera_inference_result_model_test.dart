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
    }).toEntity();

    expect(result.cameraId, 'opentopia-17916');
    expect(result.vehicleCount, 3);
    expect(result.emptySpaceCount, 5);
    expect(result.processedAt!.isAtSameMomentAs(processedAt), isTrue);
  });
}
