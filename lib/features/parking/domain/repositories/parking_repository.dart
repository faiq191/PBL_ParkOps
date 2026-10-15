import '../entities/parking_slot.dart';
import '../entities/parking_zone.dart';

/// Contract for parking data (CI-1). The presentation layer depends only on
/// this abstract class; the Firestore-backed implementation lives in
/// `data/repositories/` and can be swapped in tests with a fake.
abstract class ParkingRepository {
  // Realtime stream of all parking zones; UI updates automatically on Firestore changes
  Stream<List<ParkingZone>> watchZones();

  // Realtime stream of a single zone by its zone id
  Stream<ParkingZone> watchZone(String zoneId);

  // Realtime stream of parking slots for one zone from the 'slots' subcollection
  Stream<List<ParkingSlot>> watchSlots(String zoneId);
}
