import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/parking_zone.dart';

/// Bay occupancy for a zone: real per-bay data when the zone's 'slots'
/// subcollection has documents, otherwise the UI-only placeholder pattern
/// derived from the zone counts (below).
List<bool> baysFor(ParkingZone zone, List<ParkingSlot> slots) {
  if (slots.isNotEmpty) {
    return [for (final slot in slots) slot.isOccupied];
  }
  return derivePlaceholderOccupancy(
    total: zone.totalSlots,
    available: zone.availableSlots,
  );
}

/// UI-only placeholder bay occupancy, derived from zone counts. Same
/// even-distribution pattern the old `DummyLot` used, kept so the camera
/// feed and the map still render before real per-bay data exists in Firestore.
List<bool> derivePlaceholderOccupancy({
  required int total,
  required int available,
}) {
  // Distribute free slots evenly: k-th free index = floor(k * total / available)
  final free = <int>{
    for (int k = 0; k < available; k++) (k * total / available).floor(),
  };
  // true = occupied; any slot not in the 'free' set is occupied
  return List.generate(total, (i) => !free.contains(i));
}
