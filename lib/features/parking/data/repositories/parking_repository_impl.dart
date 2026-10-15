import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/parking_zone.dart';
import '../../domain/repositories/parking_repository.dart';
import '../models/parking_slot_model.dart';
import '../models/parking_zone_model.dart';
import '../seed_zones.dart';

/// Firestore-backed [ParkingRepository].
///
/// DI-1 fix: the Firestore instance is injected through the constructor
/// (instead of the old `FirebaseFirestore.instance` field initializer), so a
/// test can pass a fake. All Firestore exceptions are mapped to [Failure]
/// inside this class (CI-3) — raw errors never reach the UI.
class ParkingRepositoryImpl implements ParkingRepository {
  ParkingRepositoryImpl({required this.firestore});

  final FirebaseFirestore firestore;

  @override
  Stream<List<ParkingZone>> watchZones() async* {
    try {
      await for (final snapshot
          in firestore.collection('parking_zones').snapshots()) {
        final zones = [
          for (final doc in snapshot.docs)
            ParkingZoneModel.fromFirestore(doc.id, doc.data()).toEntity(),
        ];
        // Demo fallback: while 'parking_zones' is not seeded in Firestore,
        // serve the in-memory demo zones so the UI keeps working.
        yield zones.isNotEmpty ? zones : seedZones;
      }
    } on Object catch (e) {
      throw FirestoreFailure('Could not load parking zones', e);
    }
  }

  @override
  Stream<ParkingZone> watchZone(String zoneId) async* {
    try {
      await for (final doc in _watchZoneDoc(zoneId)) {
        // CI-3 fix: a deleted document used to crash on doc.data()! — skip
        // it instead and the stream simply stays on the last valid zone.
        final data = doc.data();
        if (data == null) continue;
        yield ParkingZoneModel.fromFirestore(doc.id, data).toEntity();
      }
    } on Object catch (e) {
      throw FirestoreFailure('Could not load zone "$zoneId"', e);
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _watchZoneDoc(String zoneId) {
    return firestore.collection('parking_zones').doc(zoneId).snapshots();
  }

  @override
  Stream<List<ParkingSlot>> watchSlots(String zoneId) async* {
    try {
      await for (final snapshot in firestore
          .collection('parking_zones')
          .doc(zoneId)
          .collection('slots')
          .snapshots()) {
        yield [
          for (final doc in snapshot.docs)
            ParkingSlotModel.fromFirestore(doc.id, doc.data()).toEntity(),
        ];
      }
    } on Object catch (e) {
      throw FirestoreFailure('Could not load slots for zone "$zoneId"', e);
    }
  }
}
