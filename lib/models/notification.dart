// lib/models/notification.dart

class AppNotification {
  int? id;
  String title;
  String body;
  String type;
  String date;
  bool isRead;
  int? studentId;

  AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.date,
    this.isRead = false,
    this.studentId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'date': date,
    'isRead': isRead ? 1 : 0,
    'studentId': studentId,
  };

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
    id: m['id'],
    title: m['title'],
    body: m['body'],
    type: m['type'],
    date: m['date'],
    isRead: (m['isRead'] ?? 0) == 1,
    studentId: m['studentId'],
  );
}