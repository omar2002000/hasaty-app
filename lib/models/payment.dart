// lib/models/payment.dart

class Payment {
  int? id;
  int studentId;
  String studentName;
  double amount;
  String date;
  String note;
  String type;

  Payment({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.date,
    required this.note,
    this.type = 'charge',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'amount': amount,
    'date': date,
    'note': note,
    'type': type,
  };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
    id: m['id'],
    studentId: m['studentId'],
    studentName: m['studentName'],
    amount: (m['amount'] ?? 0).toDouble(),
    date: m['date'],
    note: m['note'] ?? '',
    type: m['type'] ?? 'charge',
  );
}