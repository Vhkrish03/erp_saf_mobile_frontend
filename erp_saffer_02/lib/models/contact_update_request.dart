class ContactUpdateRequest {
  final String email;
  final String phone;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;

  ContactUpdateRequest({
    required this.email,
    required this.phone,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "phone": phone,
      "address": address,
      "emergencyContactName": emergencyContactName,
      "emergencyContactPhone": emergencyContactPhone,
    };
  }
}