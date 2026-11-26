import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:typed_data';

import '../../domain/entities/camera_inference_result.dart';

class CameraInferenceResultModel {
  CameraInferenceResultModel._(this._entity);

  final CameraInferenceResult _entity;

  factory CameraInferenceResultModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final processedAt = data['processedAt'];
    final rawDetections = data['detections'];
    final framePreview = data['framePreview'];
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
        detections: rawDetections is List
            ? [
                for (final item in rawDetections)
                  if (item is Map<String, dynamic>) _parseDetection(item),
              ]
            : const [],
        frameWidth: (data['frameWidth'] as num? ?? 0).toInt(),
        frameHeight: (data['frameHeight'] as num? ?? 0).toInt(),
        framePreview: switch (framePreview) {
          Blob value => value.bytes,
          Uint8List value => value,
          _ => null,
        },
      ),
    );
  }

  CameraInferenceResult toEntity() => _entity;

  static CameraDetection _parseDetection(Map<String, dynamic> data) {
    final rawBox = data['box'];
    return CameraDetection(
      className: data['className'] as String? ?? 'object',
      confidence: (data['confidence'] as num? ?? 0).toDouble(),
      box: rawBox is List
          ? [for (final coordinate in rawBox) (coordinate as num).toDouble()]
          : const [],
    );
  }
}
