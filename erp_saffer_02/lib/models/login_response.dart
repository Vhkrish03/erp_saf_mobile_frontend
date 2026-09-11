class LoginResponse {

  final bool success;
  final String message;
  final String role;
  final int? id;
  final String? fullName;
  final String? email;
  final String? referenceId;

  LoginResponse({
    required this.success,
    required this.message,
    required this.role,
    this.id,
    this.fullName,
    this.email,
    this.referenceId,
  });


  factory LoginResponse.fromJson(Map<String, dynamic> json) {

    return LoginResponse(
      success: json['success'],
      message: json['message'],
      role: json['role'],
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      referenceId: json['referenceId'],
    );
  }
}