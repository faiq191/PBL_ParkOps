import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingReport {
  const ParkingReport({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.type,
    required this.description,
    required this.status,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String zoneId;
  final String zoneName;
  final String type;
  final String description;
  final String status;
  final String email;
  final DateTime? createdAt;

  factory ParkingReport.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return ParkingReport(
      id: id,
      zoneId: (data['zoneId'] as String?) ?? '',
      zoneName: (data['zoneName'] as String?) ?? 'Unknown lot',
      type: (data['type'] as String?) ?? 'Other',
      description: (data['description'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'open',
      email: (data['email'] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}

class ReportRepository {
  ReportRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  Future<void> submit({
    required String uid,
    required String email,
    required String zoneId,
    required String zoneName,
    required String type,
    required String description,
  }) async {
    await _reports.add({
      'uid': uid,
      'email': email,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'type': type,
      'description': description,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ParkingReport>> watchRecent({int limit = 5}) {
    return _reports
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ParkingReport.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
