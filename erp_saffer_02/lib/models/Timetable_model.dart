class TimetableModel {
  final int id;
  final String day;
  final String time;
  final String subject;
  final String room;
  final String faculty;

  final String? employeeId;
  final String year;
  final String section;
  final String department;

  TimetableModel({
    required this.id,
    required this.day,
    required this.time,
    required this.subject,
    required this.room,
    required this.faculty,
    this.employeeId,
    required this.year,
    required this.section,
    required this.department,
  });

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json["id"],
      day: json["day"],
      time: json["time"],
      subject: json["subject"],
      room: json["room"],
      faculty: json["faculty"],
      employeeId: json["employeeId"],
      year: json["year"],
      section: json["section"],
      department: json["department"],
    );
  }
}
