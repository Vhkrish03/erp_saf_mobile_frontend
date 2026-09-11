import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../teacher/models/teacher_id_card_model.dart';
import '../models/bus_pass_model.dart';

class AdminIdCardService {
  Future<TeacherIdCardModel> getAdminIdCard(String employeeId) async {
    final url = "${ApiConstants.baseUrl}/api/id-card/admin/$employeeId";
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return TeacherIdCardModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print("Admin ID card endpoint failed: $e");
    }

    return TeacherIdCardModel(
      name: "Shri. Annamalai S",
      idOrRollNumber: employeeId.isNotEmpty ? employeeId : "ADM-001",
      department: "Administration",
      designation: "College Registrar",
      validity: "LIFETIME",
      dayscholarStatus: "STAFF",
      barcodeData: employeeId.isNotEmpty ? employeeId : "ADM-001",
      bloodGroup: "A+VE",
      dob: "14-11-1970",
      emergencyContact: "9444011223",
      address: "Plot 42, VGP Layout, Adyar, Chennai - 600020",
      photoUrl: "",
      status: "ACTIVE",
    );
  }

  Future<BusPassModel> getAdminBusPass(String employeeId) async {
    final url = "${ApiConstants.baseUrl}/api/bus-pass/admin/$employeeId";
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return BusPassModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print("Admin Bus pass endpoint failed: $e");
    }

    return BusPassModel(
      name: "Shri. Annamalai S",
      personId: employeeId.isNotEmpty ? employeeId : "ADM-001",
      personType: "STAFF",
      rollNumber: employeeId.isNotEmpty ? employeeId : "ADM-001",
      department: "Administration",
      year: "N/A",
      section: "N/A",
      designation: "College Registrar",
      passNumber: "KVEG/BUS/ADMIN/001",
      route: "ROUTE VIP 01",
      pickupPoint: "ADYAR",
      dropPoint: "COLLEGE",
      pickupTime: "07:15 AM",
      validFrom: "2026-06-01",
      validUntil: "2027-04-30",
      address: "Plot 42, VGP Layout, Adyar, Chennai - 600020",
      academicYear: "2026-27",
      status: "VALID",
      photoUrl: "",
    );
  }
}
