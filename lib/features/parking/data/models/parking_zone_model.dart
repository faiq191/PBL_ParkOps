import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/parking_zone.dart';

/// Firestore model for [ParkingZone] (CI-2): keeps the mapping out of the
/// business object. `toEntity()` hands a pure entity to the domain layer.
class ParkingZoneModel {
  ParkingZoneModel._(this._entity);

  final ParkingZone _entity;

  // Map a Firestore document to ParkingZone (defaults for missing fields)
  factory ParkingZoneModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ParkingZoneModel._(
      ParkingZone(
        id: id,
        name: data['name'] ?? '',
        location: data['location'] ?? '',
        totalSlots: data['totalSlots'] ?? 0,
        availableSlots: data['availableSlots'] ?? 0,
        // CI-3 fix: Firestore returns a Timestamp, not a DateTime — convert
        // here so reading the field never crashes at runtime.
        lastUpdated: _asDateTime(data['lastUpdated']) ?? DateTime.now(),
        cameraImageUrl: data['cameraImageUrl'] ?? '',
      ),
    );
  }

  ParkingZone toEntity() => _entity;

  // Accepts both Timestamp (real Firestore) and DateTime (tests/mocks)
  static DateTime? _asDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
