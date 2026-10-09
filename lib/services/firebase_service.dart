import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_zone.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Realtime stream of all parking zones; UI updates automatically on Firestore changes
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

  // Realtime stream of parking slots for one zone from the 'slots' subcollection
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