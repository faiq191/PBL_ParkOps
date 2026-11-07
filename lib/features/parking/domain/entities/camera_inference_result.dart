import 'dart:typed_data';

class CameraDetection {
  const CameraDetection({
    required this.className,
    required this.confidence,
    required this.box,
  });

  final String className;
  final double confidence;
  final List<double> box;
}

class CameraInferenceResult {
  const CameraInferenceResult({
    required this.cameraId,
    required this.vehicleCount,
    required this.emptySpaceCount,
    required this.processedAt,
    required this.detections,
    required this.frameWidth,
    required this.frameHeight,
    required this.framePreview,
  });

  final String cameraId;
  final int vehicleCount;
  final int emptySpaceCount;
  final DateTime? processedAt;
  final List<CameraDetection> detections;
  final int frameWidth;
  final int frameHeight;
  final Uint8List? framePreview;
}
