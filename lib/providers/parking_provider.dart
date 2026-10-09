import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parking_zone.dart';
import '../services/firebase_service.dart';

// A single FirebaseService instance shared across all providers
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Stream of all parking zones (realtime from Firestore)
final zonesStreamProvider = StreamProvider<List<ParkingZone>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.watchZones();
});

// Stream of a single zone by its zone id
final zoneStreamProvider =
    StreamProvider.family<ParkingZone, String>((ref, zoneId) {
  final service = ref.watch(firebaseServiceProvider);
  return service.watchZone(zoneId);
});

// Stream of parking slots for a given zone
final slotsStreamProvider =
    StreamProvider.family<List<ParkingSlot>, String>((ref, zoneId) {
  final service = ref.watch(firebaseServiceProvider);
  return service.watchSlots(zoneId);
});