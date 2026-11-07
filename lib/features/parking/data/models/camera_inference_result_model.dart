import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/camera_inference_result.dart';

class CameraInferenceResultModel {
  CameraInferenceResultModel._(this._entity);

  final CameraInferenceResult _entity;

  factory CameraInferenceResultModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final processedAt = data['processedAt'];
    return CameraInferenceResultModel._(
      CameraInferenceResult(
        cameraId: id,
        vehicleCount: (data['vehicleCount'] as num? ?? 0).toInt(),
        emptySpaceCount: (data['emptySpaceCount'] as num? ?? 0).toInt(),
        processedAt: processedAt is Timestamp
            ? processedAt.toDate()
            : processedAt is DateTime
            ? processedAt
            : null,
      ),
    );
  }

  CameraInferenceResult toEntity() => _entity;
}
