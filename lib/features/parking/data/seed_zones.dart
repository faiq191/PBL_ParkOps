import '../domain/entities/parking_zone.dart';

/// UI-only placeholder data. Replace with real data once the backend is ready.
///
/// This is the former `dummyLots` list from `widgets/dummy_lots.dart`, moved
/// into the data layer (CI-2/DV-3) so the UI no longer reads a global. The
/// repository serves it while the Firestore 'parking_zones' collection is
/// empty, which keeps the app demo-able before the backend is seeded.
final List<ParkingZone> seedZones = [
  ParkingZone(
    id: 'lot1',
    name: 'Graha Polinema',
    location: 'Front parking area',
    totalSlots: 48,
    availableSlots: 18,
    lastUpdated: DateTime.now(),
    cameraImageUrl: 'CAM 01',
  ),
  ParkingZone(
    id: 'lot2',
    name: 'North Lot',
    location: 'Beside the library',
    totalSlots: 32,
    availableSlots: 4,
    lastUpdated: DateTime.now(),
    cameraImageUrl: 'CAM 02',
  ),
  ParkingZone(
    id: 'lot3',
    name: 'South Lot',
    location: 'Behind the workshop',
    totalSlots: 24,
    availableSlots: 0,
    lastUpdated: DateTime.now(),
    cameraImageUrl: 'CAM 03',
  ),
];
