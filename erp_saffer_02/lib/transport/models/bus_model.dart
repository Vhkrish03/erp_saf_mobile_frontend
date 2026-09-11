import 'driver_model.dart';
import 'route_model.dart';

class BusModel {
  final int id;
  final String busNumber;
  final String registrationNumber;
  final String busType;
  final int capacity;
  final DriverModel? driver;
  final String busInchargeName;
  final RouteModel? route;
  final String status;

  BusModel({
    required this.id,
    required this.busNumber,
    required this.registrationNumber,
    required this.busType,
    required this.capacity,
    this.driver,
    required this.busInchargeName,
    this.route,
    required this.status,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      busNumber: json['busNumber']?.toString() ?? '',
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      busType: json['busType']?.toString() ?? 'STANDARD',
      capacity:
          json['capacity'] is int
              ? json['capacity']
              : int.tryParse(json['capacity']?.toString() ?? '') ?? 50,
      driver:
          json['driver'] != null ? DriverModel.fromJson(json['driver']) : null,
      busInchargeName: json['busInchargeName']?.toString() ?? '',
      route: json['route'] != null ? RouteModel.fromJson(json['route']) : null,
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'busNumber': busNumber,
    'registrationNumber': registrationNumber,
    'busType': busType,
    'capacity': capacity,
    'driver': driver?.toJson(),
    'busInchargeName': busInchargeName,
    'route': route?.toJson(),
    'status': status,
  };
}
