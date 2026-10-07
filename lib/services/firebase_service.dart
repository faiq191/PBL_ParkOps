import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_zone.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ParkingZone>> watchZones() {
    return _db.collection('parking_zones').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ParkingZone.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<ParkingZone> watchZone(String zoneId) {
    return _db
        .collection('parking_zones')
        .doc(zoneId)
        .snapshots()
        .map((doc) => ParkingZone.fromFirestore(doc.id, doc.data()!));
  }

  Stream<List<ParkingSlot>> watchSlots(String zoneId) {
    return _db
        .collection('parking_zones')
        .doc(zoneId)
        .collection('slots')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParkingSlot.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}