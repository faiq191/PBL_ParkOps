import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(FirebaseFirestore.instance);
});

final recentReportsProvider = StreamProvider<List<ParkingReport>>((ref) {
  return ref.watch(reportRepositoryProvider).watchRecent();
});
