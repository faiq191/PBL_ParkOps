import '../../parking/domain/entities/parking_zone.dart';

class ParkingNotificationContent {
  const ParkingNotificationContent({required this.title, required this.body});

  final String title;
  final String body;

  factory ParkingNotificationContent.fromZones({
    required List<ParkingZone> zones,
    required String favoriteLotId,
  }) {
    final favoriteLot = zones.where((zone) => zone.id == favoriteLotId);
    if (favoriteLot.isEmpty) {
      throw ArgumentError.value(
        favoriteLotId,
        'favoriteLotId',
        'Must match a parking zone',
      );
    }
    final favorite = favoriteLot.first;
    final availability = zones
        .map((zone) => '${zone.name}: ${zone.availableSlots} available')
        .join(' · ');
    final spaceLabel = favorite.availableSlots == 1 ? 'space' : 'spaces';
    return ParkingNotificationContent(
      title:
          '${favorite.availableSlots} $spaceLabel available at ${favorite.name}',
      body: availability,
    );
  }
}
