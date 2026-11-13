import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(FirebaseFirestore.instance);
});

/// Riverpod 3 retries a failing provider in the background, which keeps the UI
/// on a spinner for a long time. Reports fail for a clear reason (usually the
/// Firestore rules), so surface the error straight away instead.
final recentReportsProvider = StreamProvider<List<ParkingReport>>(
  (ref) => ref.watch(reportRepositoryProvider).watchRecent(),
  retry: (retryCount, error) => null,
);
