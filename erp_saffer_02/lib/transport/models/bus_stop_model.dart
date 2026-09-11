class BusStopModel {
  final int id;
  final int routeId;
  final String stopName;
  final double latitude;
  final double longitude;
  final int stopOrder;
  final String estimatedArrivalTime;
  final String status;

  BusStopModel({
    required this.id,
    required this.routeId,
    required this.stopName,
    required this.latitude,
    required this.longitude,
    required this.stopOrder,
    required this.estimatedArrivalTime,
    required this.status,
  });

  factory BusStopModel.fromJson(Map<String, dynamic> json) {
    return BusStopModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      routeId:
          json['routeId'] is int
              ? json['routeId']
              : int.tryParse(json['routeId']?.toString() ?? '') ?? 0,
      stopName: json['stopName']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      stopOrder:
          json['stopOrder'] is int
              ? json['stopOrder']
              : int.tryParse(json['stopOrder']?.toString() ?? '') ?? 0,
      estimatedArrivalTime: json['estimatedArrivalTime']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'routeId': routeId,
      'stopName': stopName,
      'latitude': latitude,
      'longitude': longitude,
      'stopOrder': stopOrder,
      'estimatedArrivalTime': estimatedArrivalTime,
      'status': status,
    };
    if (id != 0) {
      data['id'] = id;
    }
    return data;
  }
}
