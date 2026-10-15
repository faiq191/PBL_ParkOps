import '../../domain/entities/parking_slot.dart';

/// Firestore model for [ParkingSlot] (CI-2): keeps the mapping out of the
/// business object. `toEntity()` hands a pure entity to the domain layer.
class ParkingSlotModel {
  ParkingSlotModel._(this._entity);

  final ParkingSlot _entity;

  factory ParkingSlotModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ParkingSlotModel._(
      ParkingSlot(
        id: id,
        zoneId: data['zoneId'] ?? '',
        isOccupied: data['isOccupied'] ?? false,
        x: (data['x'] ?? 0).toDouble(),
        y: (data['y'] ?? 0).toDouble(),
        width: (data['width'] ?? 0).toDouble(),
        height: (data['height'] ?? 0).toDouble(),
      ),
    );
  }

  ParkingSlot toEntity() => _entity;
}
