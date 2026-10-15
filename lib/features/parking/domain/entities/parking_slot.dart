/// Pure business entity for a single parking bay inside a zone: no Firestore
/// mapping here — that lives in the data layer (CI-2).
class ParkingSlot {
  final String id;
  final String zoneId;
  final bool isOccupied;
  final double x, y, width, height;
  ParkingSlot({
    required this.id,
    required this.zoneId,
    required this.isOccupied,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}
