import 'bus_model.dart';
import 'route_model.dart';
import 'bus_stop_model.dart';
import '../../models/student.dart';

class StudentTransportAssignmentModel {
  final int id;
  final Student student;
  final BusModel bus;
  final RouteModel route;
  final BusStopModel? pickupStop;
  final BusStopModel? dropStop;
  final String status;
  final String startDate;
  final String endDate;

  StudentTransportAssignmentModel({
    required this.id,
    required this.student,
    required this.bus,
    required this.route,
    this.pickupStop,
    this.dropStop,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory StudentTransportAssignmentModel.fromJson(Map<String, dynamic> json) {
    return StudentTransportAssignmentModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      student: Student.fromJson(json['student'] ?? {}),
      bus: BusModel.fromJson(json['bus'] ?? {}),
      route: RouteModel.fromJson(json['route'] ?? {}),
      pickupStop:
          json['pickupStop'] != null
              ? BusStopModel.fromJson(json['pickupStop'])
              : null,
      dropStop:
          json['dropStop'] != null
              ? BusStopModel.fromJson(json['dropStop'])
              : null,
      status: json['status']?.toString() ?? 'ACTIVE',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
    );
  }
}
