// -----------------------------------------------------------------------
// DUMMY / STATIC DATA
// -----------------------------------------------------------------------
// This file holds hard-coded sample data so every screen has something
// to display. Replace the contents of these lists/objects with real
// values from your backend (API calls, database, etc.) once that layer
// is ready. Nothing in lib/screens should need to change structurally —
// just swap out where this data comes from.
// -----------------------------------------------------------------------

import '../models/student.dart';
import '../models/subject_model.dart';
import '../models/notice.dart';

// final Student currentStudent = const Student(
//   id: 'STU2024118',
//   name: 'Aarav Sharma',
//   rollNumber: '21CS118',
//   department: 'Computer Science & Engineering',
//   year: '3rd Year',
//   semester: 'Semester 5',
//   email: 'aarav.sharma@college.edu',
//   phone: '+91 98765 43210',
//   bloodGroup: 'B+',
//   dob: '14 Mar 2004',
//   address: '24, Lake View Colony, Chennai, Tamil Nadu',
//   advisor: 'Dr. Meera Krishnan',
//   cgpa: 8.72,
// );





// class Student {
//   final String id;
//   final String name;
//   final String rollNumber;
//   final String department;
//   final String year;
//   final String semester;
//   final String email;
//   final String phone;
//   final String bloodGroup;
//   final String dob;
//   final String address;
//   final String advisor;
//   final double cgpa;
//
//   Student({
//     required this.id,
//     required this.name,
//     required this.rollNumber,
//     required this.department,
//     required this.year,
//     required this.semester,
//     required this.email,
//     required this.phone,
//     required this.bloodGroup,
//     required this.dob,
//     required this.address,
//     required this.advisor,
//     required this.cgpa,
//   });
//
//   factory Student.fromJson(Map<String, dynamic> json) {
//     return Student(
//       id: json['id'],
//       name: json['name'],
//       rollNumber: json['rollNumber'],
//       department: json['department'],
//       year: json['year'],
//       semester: json['semester'],
//       email: json['email'],
//       phone: json['phone'],
//       bloodGroup: json['bloodGroup'],
//       dob: json['dob'],
//       address: json['address'],
//       advisor: json['advisor'],
//       cgpa: json['cgpa'].toDouble(),
//     );
//   }
// }

// final List<Subject> subjects = const [
//   Subject(
//     code: 'CS501',
//     name: 'Operating Systems',
//     faculty: 'Dr. Meera Krishnan',
//     credits: 4,
//     attendancePercent: 92.0,
//     classesHeld: 50,
//     classesAttended: 46,
//   ),
//   Subject(
//     code: 'CS502',
//     name: 'Database Management Systems',
//     faculty: 'Prof. Arjun Rao',
//     credits: 4,
//     attendancePercent: 88.0,
//     classesHeld: 48,
//     classesAttended: 42,
//   ),
//   Subject(
//     code: 'CS503',
//     name: 'Computer Networks',
//     faculty: 'Dr. Priya Nathan',
//     credits: 3,
//     attendancePercent: 76.0,
//     classesHeld: 44,
//     classesAttended: 33,
//   ),
//   Subject(
//     code: 'CS504',
//     name: 'Software Engineering',
//     faculty: 'Prof. Karthik Iyer',
//     credits: 3,
//     attendancePercent: 95.0,
//     classesHeld: 40,
//     classesAttended: 38,
//   ),
//   Subject(
//     code: 'CS505',
//     name: 'Theory of Computation',
//     faculty: 'Dr. Sandhya Menon',
//     credits: 3,
//     attendancePercent: 68.0,
//     classesHeld: 38,
//     classesAttended: 26,
//   ),
//   Subject(
//     code: 'HS506',
//     name: 'Professional Ethics',
//     faculty: 'Prof. Lakshmi Iyer',
//     credits: 2,
//     attendancePercent: 100.0,
//     classesHeld: 20,
//     classesAttended: 20,
//   ),
// ];


// class Subject {
//   final String code;
//   final String name;
//   final String faculty;
//   final int credits;
//   final double attendancePercent;
//   final int classesHeld;
//   final int classesAttended;
//
//   Subject({
//     required this.code,
//     required this.name,
//     required this.faculty,
//     required this.credits,
//     required this.attendancePercent,
//     required this.classesHeld,
//     required this.classesAttended,
//   });
//
//   factory Subject.fromJson(Map<String, dynamic> json) {
//     return Subject(
//       code: json["code"],
//       name: json["name"],
//       faculty: json["faculty"],
//       credits: json["credits"],
//       attendancePercent:
//       (json["attendancePercent"] as num).toDouble(),
//       classesHeld: json["classesHeld"],
//       classesAttended: json["classesAttended"],
//     );
//   }
// }









// final Map<String, List<TimetableSlot>> weeklyTimetable = const {
//   'Monday': [
//     TimetableSlot(time: '9:00 - 9:50', subject: 'Operating Systems', room: 'A-201', faculty: 'Dr. Meera Krishnan'),
//     TimetableSlot(time: '9:50 - 10:40', subject: 'DBMS', room: 'A-201', faculty: 'Prof. Arjun Rao'),
//     TimetableSlot(time: '11:00 - 11:50', subject: 'Computer Networks', room: 'A-105', faculty: 'Dr. Priya Nathan'),
//     TimetableSlot(time: '11:50 - 12:40', subject: 'Software Engineering', room: 'A-105', faculty: 'Prof. Karthik Iyer'),
//     TimetableSlot(time: '1:30 - 3:30', subject: 'OS Lab', room: 'Lab-3', faculty: 'Dr. Meera Krishnan'),
//   ],
//   'Tuesday': [
//     TimetableSlot(time: '9:00 - 9:50', subject: 'Theory of Computation', room: 'A-201', faculty: 'Dr. Sandhya Menon'),
//     TimetableSlot(time: '9:50 - 10:40', subject: 'Professional Ethics', room: 'A-201', faculty: 'Prof. Lakshmi Iyer'),
//     TimetableSlot(time: '11:00 - 11:50', subject: 'Operating Systems', room: 'A-105', faculty: 'Dr. Meera Krishnan'),
//     TimetableSlot(time: '11:50 - 12:40', subject: 'DBMS', room: 'A-105', faculty: 'Prof. Arjun Rao'),
//     TimetableSlot(time: '1:30 - 3:30', subject: 'DBMS Lab', room: 'Lab-1', faculty: 'Prof. Arjun Rao'),
//   ],
//   'Wednesday': [
//     TimetableSlot(time: '9:00 - 9:50', subject: 'Computer Networks', room: 'A-201', faculty: 'Dr. Priya Nathan'),
//     TimetableSlot(time: '9:50 - 10:40', subject: 'Software Engineering', room: 'A-201', faculty: 'Prof. Karthik Iyer'),
//     TimetableSlot(time: '11:00 - 11:50', subject: 'Theory of Computation', room: 'A-105', faculty: 'Dr. Sandhya Menon'),
//     TimetableSlot(time: '11:50 - 12:40', subject: 'Operating Systems', room: 'A-105', faculty: 'Dr. Meera Krishnan'),
//   ],
//   'Thursday': [
//     TimetableSlot(time: '9:00 - 9:50', subject: 'DBMS', room: 'A-201', faculty: 'Prof. Arjun Rao'),
//     TimetableSlot(time: '9:50 - 10:40', subject: 'Computer Networks', room: 'A-201', faculty: 'Dr. Priya Nathan'),
//     TimetableSlot(time: '11:00 - 11:50', subject: 'Professional Ethics', room: 'A-105', faculty: 'Prof. Lakshmi Iyer'),
//     TimetableSlot(time: '1:30 - 3:30', subject: 'Networks Lab', room: 'Lab-2', faculty: 'Dr. Priya Nathan'),
//   ],
//   'Friday': [
//     TimetableSlot(time: '9:00 - 9:50', subject: 'Software Engineering', room: 'A-201', faculty: 'Prof. Karthik Iyer'),
//     TimetableSlot(time: '9:50 - 10:40', subject: 'Theory of Computation', room: 'A-201', faculty: 'Dr. Sandhya Menon'),
//     TimetableSlot(time: '11:00 - 11:50', subject: 'Operating Systems', room: 'A-105', faculty: 'Dr. Meera Krishnan'),
//     TimetableSlot(time: '11:50 - 12:40', subject: 'DBMS', room: 'A-105', faculty: 'Prof. Arjun Rao'),
//   ],
//   'Saturday': [
//     TimetableSlot(time: '9:00 - 10:40', subject: 'Seminar / Project Review', room: 'Seminar Hall', faculty: 'Dept. Committee'),
//   ],
// };

// final List<SemesterResult> semesterResults = const [
//   SemesterResult(
//     semesterName: 'Semester 4',
//     // semesterNO: 'Semester 4',
//     sgpa: 8.6,
//     results: [
//       ExamResult(subjectCode: 'CS401', subjectName: 'Design & Analysis of Algorithms', grade: 'A', gradePoint: 9.0, marksObtained: 88, maxMarks: 100),
//       ExamResult(subjectCode: 'CS402', subjectName: 'Object Oriented Programming', grade: 'A+', gradePoint: 10.0, marksObtained: 95, maxMarks: 100),
//       ExamResult(subjectCode: 'CS403', subjectName: 'Discrete Mathematics', grade: 'B+', gradePoint: 8.0, marksObtained: 78, maxMarks: 100),
//       ExamResult(subjectCode: 'CS404', subjectName: 'Computer Organization', grade: 'A', gradePoint: 9.0, marksObtained: 85, maxMarks: 100),
//       ExamResult(subjectCode: 'HS405', subjectName: 'Technical Communication', grade: 'B+', gradePoint: 8.0, marksObtained: 80, maxMarks: 100),
//     ],
//   ),
//   SemesterResult(
//     semesterName: 'Semester 3',
//     sgpa: 8.4,
//     results: [
//       ExamResult(subjectCode: 'CS301', subjectName: 'Data Structures', grade: 'A', gradePoint: 9.0, marksObtained: 87, maxMarks: 100),
//       ExamResult(subjectCode: 'CS302', subjectName: 'Digital Logic Design', grade: 'B+', gradePoint: 8.0, marksObtained: 76, maxMarks: 100),
//       ExamResult(subjectCode: 'CS303', subjectName: 'Probability & Statistics', grade: 'A', gradePoint: 9.0, marksObtained: 84, maxMarks: 100),
//       ExamResult(subjectCode: 'CS304', subjectName: 'Environmental Science', grade: 'A+', gradePoint: 10.0, marksObtained: 92, maxMarks: 100),
//     ],
//   ),
// ];

// final List<Notice> notices = const [
//   Notice(
//     title: 'Semester 5 Internal Assessment II Schedule Released',
//     description: 'The IA-II timetable for all CSE sections has been published on the department board. Exams begin next Monday.',
//     date: '10 Jul 2026',
//     category: NoticeCategory.exam,
//     isImportant: true,
//   ),
//   Notice(
//     title: 'Annual Tech Fest "Ignite 2026" Registrations Open',
//     description: 'Register your team for coding, robotics, and design events before 20 Jul. Limited slots per event.',
//     date: '08 Jul 2026',
//     category: NoticeCategory.event,
//   ),
//   Notice(
//     title: 'Library Timings Extended During Exam Week',
//     description: 'The central library will remain open until 10 PM from 14 Jul to 22 Jul for exam preparation.',
//     date: '07 Jul 2026',
//     category: NoticeCategory.general,
//   ),
//   Notice(
//     title: 'Founders Day Holiday',
//     description: 'College will remain closed on 15 Jul on account of Founders Day. Regular classes resume the next day.',
//     date: '05 Jul 2026',
//     category: NoticeCategory.holiday,
//   ),
//   Notice(
//     title: 'Guest Lecture on Cloud Architecture',
//     description: 'Department of CSE invites all 3rd and 4th year students to a guest lecture by an industry expert on 18 Jul.',
//     date: '03 Jul 2026',
//     category: NoticeCategory.academic,
//   ),
// ];

// final List<FeeItem> feeItems = const [
//   FeeItem(particular: 'Tuition Fee - Semester 5', amount: 62000, isPaid: true, dueDate: '15 Jun 2026'),
//   FeeItem(particular: 'Hostel & Mess Fee', amount: 38000, isPaid: true, dueDate: '15 Jun 2026'),
//   FeeItem(particular: 'Examination Fee', amount: 2500, isPaid: false, dueDate: '20 Jul 2026'),
//   FeeItem(particular: 'Library & Lab Fee', amount: 3000, isPaid: false, dueDate: '20 Jul 2026'),
//   FeeItem(particular: 'Student Activity Fee', amount: 1500, isPaid: true, dueDate: '15 Jun 2026'),
// ];
 
// final List<LibraryBook> issuedBooks = const [
//   LibraryBook(
//     title: 'Operating System Concepts',
//     author: 'Abraham Silberschatz',
//     issueDate: '20 Jun 2026',
//     dueDate: '20 Jul 2026',
//     isOverdue: false,
//   ),
//   LibraryBook(
//     title: 'Computer Networks',
//     author: 'Andrew S. Tanenbaum',
//     issueDate: '02 Jun 2026',
//     dueDate: '02 Jul 2026',
//     isOverdue: true,
//   ),
// ];


