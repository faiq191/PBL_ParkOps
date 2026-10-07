import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parking_zone.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final zonesStreamProvider = StreamProvider<List<ParkingZone>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.watchZones();
});

final zoneStreamProvider =
    StreamProvider.family<ParkingZone, String>((ref, zoneId) {
  final service = ref.watch(firebaseServiceProvider);
  return service.watchZone(zoneId);
});

final slotsStreamProvider =
    StreamProvider.family<List<ParkingSlot>, String>((ref, zoneId) {
  final service = ref.watch(firebaseServiceProvider);
  return service.watchSlots(zoneId);
});