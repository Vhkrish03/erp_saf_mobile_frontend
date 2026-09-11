import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bus_model.dart';
import '../models/driver_model.dart';
import '../models/route_model.dart';
import '../models/bus_stop_model.dart';
import '../models/bus_location_model.dart';
import '../../core/api_constants.dart';
import '../models/student_transport_assignment_model.dart';

class BusService {
  static String get baseUrl => "${ApiConstants.baseUrl}/api";

  // ==========================================
  // DRIVER CRUD APIs
  // ==========================================
  Future<List<DriverModel>> getDrivers() async {
    final response = await http.get(Uri.parse("$baseUrl/admin/drivers"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => DriverModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load drivers");
    }
  }

  Future<DriverModel> createDriver(DriverModel driver) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/drivers"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(driver.toJson()),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return DriverModel.fromJson(jsonDecode(response.body));
    } else {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  Future<DriverModel> updateDriver(int id, DriverModel driver) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/drivers/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(driver.toJson()),
    );
    if (response.statusCode == 200) {
      return DriverModel.fromJson(jsonDecode(response.body));
    } else {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  Future<void> deleteDriver(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/admin/drivers/$id"));
    if (response.statusCode != 200) {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  // ==========================================
  // ROUTE CRUD APIs
  // ==========================================
  Future<List<RouteModel>> getRoutes() async {
    final response = await http.get(Uri.parse("$baseUrl/admin/routes"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => RouteModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load routes");
    }
  }

  Future<RouteModel> createRoute(RouteModel route) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/routes"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(route.toJson()),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return RouteModel.fromJson(jsonDecode(response.body));
    } else {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  Future<RouteModel> updateRoute(int id, RouteModel route) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/routes/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(route.toJson()),
    );
    if (response.statusCode == 200) {
      return RouteModel.fromJson(jsonDecode(response.body));
    } else {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  Future<void> deleteRoute(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/admin/routes/$id"));
    if (response.statusCode != 200) {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  // ==========================================
  // BUS STOP CRUD APIs
  // ==========================================
  Future<List<BusStopModel>> getStops(int routeId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/bus-stops?routeId=$routeId"),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => BusStopModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load stops");
    }
  }

  Future<BusStopModel> createStop(BusStopModel stop) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/bus-stops"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(stop.toJson()),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return BusStopModel.fromJson(jsonDecode(response.body));
    } else {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  Future<BusStopModel> updateStop(int id, BusStopModel stop) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/bus-stops/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(stop.toJson()),
    );
    if (response.statusCode == 200) {
      return BusStopModel.fromJson(jsonDecode(response.body));
    } else {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  Future<void> deleteStop(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/bus-stops/$id"),
    );
    if (response.statusCode != 200) {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  // ==========================================
  // BUS CRUD APIs
  // ==========================================
  Future<List<BusModel>> getBuses() async {
    final response = await http.get(Uri.parse("$baseUrl/admin/buses"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => BusModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load buses");
    }
  }

  Future<BusModel> createBus(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/buses"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return BusModel.fromJson(jsonDecode(response.body));
    } else {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  Future<BusModel> updateBus(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/buses/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return BusModel.fromJson(jsonDecode(response.body));
    } else {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  Future<void> deleteBus(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/admin/buses/$id"));
    if (response.statusCode != 200) {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  // ==========================================
  // STUDENT ASSIGNMENT APIs
  // ==========================================
  Future<List<StudentTransportAssignmentModel>> getAssignments() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/transport-assignments"),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => StudentTransportAssignmentModel.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load transport assignments");
    }
  }

  Future<StudentTransportAssignmentModel> assignStudent(
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/transport-assignments"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return StudentTransportAssignmentModel.fromJson(
        jsonDecode(response.body),
      );
    } else {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  Future<void> deactivateAssignment(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/transport-assignments/$id"),
    );
    if (response.statusCode != 200) {
      final errMsg = jsonDecode(response.body)['message'] ?? "Unknown error";
      throw Exception(errMsg);
    }
  }

  // ==========================================
  // STUDENT TRACKING & MY BUS
  // ==========================================
  Future<StudentTransportAssignmentModel?> getStudentTransportProfile(
    String referenceId,
    String role,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/student/transport?referenceId=$referenceId&role=$role",
      ),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'NOT_ASSIGNED') {
        return null;
      }
      return StudentTransportAssignmentModel.fromJson(data);
    } else {
      throw Exception("Failed to load student transport profile");
    }
  }

  Future<BusLocationModel> getMyBusLocation(
    String referenceId,
    String role,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/student/my-bus/location?referenceId=$referenceId&role=$role",
      ),
    );
    if (response.statusCode == 200) {
      return BusLocationModel.fromJson(jsonDecode(response.body));
    } else {
      final errMsg =
          jsonDecode(response.body)['message'] ??
          "Failed to load my bus location";
      throw Exception(errMsg);
    }
  }

  Future<RouteModel> getMyBusRoute(String referenceId, String role) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/student/my-bus/route?referenceId=$referenceId&role=$role",
      ),
    );
    if (response.statusCode == 200) {
      return RouteModel.fromJson(jsonDecode(response.body));
    } else {
      final errMsg =
          jsonDecode(response.body)['message'] ?? "Failed to load my bus route";
      throw Exception(errMsg);
    }
  }

  Future<List<BusStopModel>> getMyBusStops(
    String referenceId,
    String role,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/student/my-bus/stops?referenceId=$referenceId&role=$role",
      ),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => BusStopModel.fromJson(e)).toList();
    } else {
      final errMsg =
          jsonDecode(response.body)['message'] ?? "Failed to load my bus stops";
      throw Exception(errMsg);
    }
  }

  // ==========================================
  // GPS LOCATION MOCKING/UPDATE
  // ==========================================
  Future<void> sendLocationUpdate(
    int busId,
    double lat,
    double lng,
    double speed,
    double heading,
    String status,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/bus-tracking/location"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "busId": busId,
        "latitude": lat,
        "longitude": lng,
        "speed": speed,
        "heading": heading,
        "status": status,
      }),
    );
    if (response.statusCode != 200) {
      final errMsg =
          jsonDecode(response.body)['message'] ??
          "Failed to update GPS tracker";
      throw Exception(errMsg);
    }
  }
}
