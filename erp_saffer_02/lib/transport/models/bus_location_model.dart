class BusLocationModel {
  final int id;
  final int busId;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final String lastUpdated;
  final String status;

  BusLocationModel({
    required this.id,
    required this.busId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.lastUpdated,
    required this.status,
  });

  factory BusLocationModel.fromJson(Map<String, dynamic> json) {
    return BusLocationModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      busId:
          json['busId'] is int
              ? json['busId']
              : int.tryParse(json['busId']?.toString() ?? '') ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      lastUpdated:
          json['lastUpdated']?.toString() ??
          json['recordedAt']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'NOT_STARTED',
    );
  }
}
