// lib/models/academic_record.dart

class AcademicRecord {
  int? id;
  int studentId;
  String studentName;
  String groupName;
  String type;
  String grade;
  String date;
  String? sessionTopic;
  String? note;

  AcademicRecord({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.groupName,
    required this.type,
    required this.grade,
    required this.date,
    this.sessionTopic,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'groupName': groupName,
    'type': type,
    'grade': grade,
    'date': date,
    'sessionTopic': sessionTopic,
    'note': note,
  };

  factory AcademicRecord.fromMap(Map<String, dynamic> m) => AcademicRecord(
    id: m['id'],
    studentId: m['studentId'],
    studentName: m['studentName'],
    groupName: m['groupName'],
    type: m['type'],
    grade: m['grade'],
    date: m['date'],
    sessionTopic: m['sessionTopic'],
    note: m['note'],
  );
}