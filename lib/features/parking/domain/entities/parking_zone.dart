/// Availability status of a parking zone. Declared as an enum (CI-2) so the
/// old magic strings 'full' / 'tight' / 'ok' are replaced by typed values and
/// the rule lives in exactly one place.
enum ZoneStatus { full, tight, ok }

/// Pure business entity for a parking zone: no Firestore mapping and no
/// Flutter types here — those belong to the data and presentation layers.
class ParkingZone {
  final String id;
  final String name;
  final String location;
  final int totalSlots;
  final int availableSlots;
  final DateTime lastUpdated;
  final String cameraImageUrl;

  ParkingZone({
    required this.id,
    required this.name,
    required this.location,
    required this.totalSlots,
    required this.availableSlots,
    required this.lastUpdated,
    required this.cameraImageUrl,
  });

  int get occupiedSlots => totalSlots - availableSlots;

  // Status: 'full' when no slots remain, 'tight' when <= 20% remain, otherwise 'ok'
  ZoneStatus get status {
    if (availableSlots == 0) return ZoneStatus.full;
    if (availableSlots <= (totalSlots * 0.2)) return ZoneStatus.tight;
    return ZoneStatus.ok;
  }
}
