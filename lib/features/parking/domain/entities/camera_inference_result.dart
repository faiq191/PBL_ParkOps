class CameraInferenceResult {
  const CameraInferenceResult({
    required this.cameraId,
    required this.vehicleCount,
    required this.emptySpaceCount,
    required this.processedAt,
  });

  final String cameraId;
  final int vehicleCount;
  final int emptySpaceCount;
  final DateTime? processedAt;
}
