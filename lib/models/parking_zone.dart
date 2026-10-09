class ParkingZone {
  final String id;
  final String name;
  final String location;
  final int totalSlots;
  final int availableSlots;
  final DateTime lastUpdated;
  final String cameraImageUrl;

  ParkingZone({
    required this.id,
    required this.name,
    required this.location,
    required this.totalSlots,
    required this.availableSlots,
    required this.lastUpdated,
    required this.cameraImageUrl,
  });

  int get occupiedSlots => totalSlots - availableSlots;

  // Status: 'full' when no slots remain, 'tight' when <= 20% remain, otherwise 'ok'
  String get status {
    if (availableSlots == 0) return 'full';
    if (availableSlots <= (totalSlots * 0.2)) return 'tight';
    return 'ok';
  }

  // Map a Firestore document to ParkingZone (defaults for missing fields)
  factory ParkingZone.fromFirestore(String id, Map<String, dynamic> data) {
    return ParkingZone(
      id: id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      totalSlots: data['totalSlots'] ?? 0,
      availableSlots: data['availableSlots'] ?? 0,
      lastUpdated: (data['lastUpdated'] as DateTime?) ?? DateTime.now(),
      cameraImageUrl: data['cameraImageUrl'] ?? '',
    );
  }
}

class ParkingSlot {
  final String id;
  final String zoneId;
  final bool isOccupied;
  final double x, y, width, height; 
  ParkingSlot({
    required this.id,
    required this.zoneId,
    required this.isOccupied,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory ParkingSlot.fromFirestore(String id, Map<String, dynamic> data) {
    return ParkingSlot(
      id: id,
      zoneId: data['zoneId'] ?? '',
      isOccupied: data['isOccupied'] ?? false,
      x: (data['x'] ?? 0).toDouble(),
      y: (data['y'] ?? 0).toDouble(),
      width: (data['width'] ?? 0).toDouble(),
      height: (data['height'] ?? 0).toDouble(),
    );
  }
}