import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/parking_zone.dart';

// Stream of all parking zones (realtime from Firestore)
final zonesStreamProvider = StreamProvider<List<ParkingZone>>((ref) {
  return ref.watch(parkingRepositoryProvider).watchZones();
});

// Zones as a plain list (empty while loading or after an error) — used by
// widgets that render lists and already handle the empty case.
final zonesListProvider = Provider<List<ParkingZone>>((ref) {
  return ref.watch(zonesStreamProvider).value ?? const <ParkingZone>[];
});

// Aggregate free and total slots across all zones for the hero card.
// Moved out of Homepage.build (Grep 2 fix: no business logic in build()).
final zoneTotalsProvider = Provider<({int available, int total})>((ref) {
  final zones = ref.watch(zonesListProvider);
  return (
    available: zones.fold<int>(0, (acc, zone) => acc + zone.availableSlots),
    total: zones.fold<int>(0, (acc, zone) => acc + zone.totalSlots),
  );
});

/// Lot currently picked. Shared by the Home, Camera and Map tabs.
/// DV-3 fix: replaces the global `ValueNotifier<int> selectedLotIndex` from
/// widgets/dummy_lots.dart with Riverpod state.
class SelectedZoneId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String zoneId) => state = zoneId;
}

final selectedZoneIdProvider =
    NotifierProvider<SelectedZoneId, String?>(SelectedZoneId.new);

/// The zone the Home/Camera/Map tabs are currently focused on: the selected
/// zone if it still exists, otherwise the first zone as a sensible default.
final selectedZoneProvider = Provider<ParkingZone?>((ref) {
  final zones = ref.watch(zonesListProvider);
  if (zones.isEmpty) return null;
  final selectedId = ref.watch(selectedZoneIdProvider);
  for (final zone in zones) {
    if (zone.id == selectedId) return zone;
  }
  return zones.first;
});

// Stream of a single zone by its zone id
final zoneStreamProvider =
    StreamProvider.family<ParkingZone, String>((ref, zoneId) {
  return ref.watch(parkingRepositoryProvider).watchZone(zoneId);
});

// Stream of parking slots for a given zone
final slotsStreamProvider =
    StreamProvider.family<List<ParkingSlot>, String>((ref, zoneId) {
  return ref.watch(parkingRepositoryProvider).watchSlots(zoneId);
});
