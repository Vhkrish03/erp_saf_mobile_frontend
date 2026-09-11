/// A single scheduled class slot (used for both "Today's Schedule"
/// on the dashboard and the full weekly Timetable screen).
class ScheduleSlot {
  final String time;
  final String subject;
  final String section;
  final String room;
  final String day; // e.g. Monday..Saturday, unused for "today" views

  const ScheduleSlot({
    required this.time,
    required this.subject,
    required this.section,
    required this.room,
    this.day = '',
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      time: json['time'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      section: json['section'] as String? ?? '',
      room: json['room'] as String? ?? '',
      day: json['day'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'subject': subject,
      'section': section,
      'room': room,
      'day': day,
    };
  }
}

/// A full weekly timetable, grouped by day.
class WeeklyTimetable {
  final Map<String, List<ScheduleSlot>> byDay;

  const WeeklyTimetable({required this.byDay});

  factory WeeklyTimetable.fromJson(Map<String, dynamic> json) {
    final map = <String, List<ScheduleSlot>>{};
    json.forEach((day, slots) {
      map[day] = (slots as List)
          .map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    return WeeklyTimetable(byDay: map);
  }

  Map<String, dynamic> toJson() {
    return byDay.map((day, slots) => MapEntry(day, slots.map((s) => s.toJson()).toList()));
  }
}
