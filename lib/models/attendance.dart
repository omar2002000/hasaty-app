// lib/models/attendance.dart

class AttendanceRecord {
  int? id;
  int studentId;
  String studentName;
  String groupName;
  String date;
  bool present;

  AttendanceRecord({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.groupName,
    required this.date,
    required this.present,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'groupName': groupName,
    'date': date,
    'present': present ? 1 : 0,
  };

  factory AttendanceRecord.fromMap(Map<String, dynamic> m) => AttendanceRecord(
    id: m['id'],
    studentId: m['studentId'],
    studentName: m['studentName'],
    groupName: m['groupName'],
    date: m['date'],
    present: (m['present'] ?? 0) == 1,
  );
}