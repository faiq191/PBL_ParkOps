import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../data/camera_feeds.dart';
import '../../domain/entities/camera_feed.dart';
import '../../domain/entities/camera_inference_result.dart';
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

/// Lot currently picked. Shared by the Home, Camera and Map tabs.
/// DV-3 fix: replaces the global `ValueNotifier<int> selectedLotIndex` from
/// widgets/dummy_lots.dart with Riverpod state.
class SelectedZoneId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String zoneId) => state = zoneId;
}

final selectedZoneIdProvider = NotifierProvider<SelectedZoneId, String?>(
  SelectedZoneId.new,
);

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

class SelectedCameraId extends Notifier<String> {
  @override
  String build() => defaultCameraId;

  void select(String cameraId) {
    if (cameraFeeds.any((feed) => feed.id == cameraId)) state = cameraId;
  }
}

final selectedCameraIdProvider = NotifierProvider<SelectedCameraId, String>(
  SelectedCameraId.new,
);

final selectedCameraFeedProvider = Provider<CameraFeed>((ref) {
  final selectedId = ref.watch(selectedCameraIdProvider);
  return cameraFeeds.firstWhere((feed) => feed.id == selectedId);
});

// Stream of a single zone by its zone id
final zoneStreamProvider = StreamProvider.family<ParkingZone, String>((
  ref,
  zoneId,
) {
  return ref.watch(parkingRepositoryProvider).watchZone(zoneId);
});

// Stream of parking slots for a given zone
final slotsStreamProvider = StreamProvider.family<List<ParkingSlot>, String>((
  ref,
  zoneId,
) {
  return ref.watch(parkingRepositoryProvider).watchSlots(zoneId);
});

final cameraInferenceStreamProvider =
    StreamProvider.family<CameraInferenceResult?, String>((ref, cameraId) {
      return ref
          .watch(parkingRepositoryProvider)
          .watchCameraInference(cameraId);
    });
