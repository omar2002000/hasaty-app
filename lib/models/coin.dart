// lib/models/coin.dart

class CoinTransaction {
  int? id;
  int studentId;
  String studentName;
  int amount;
  String reason;
  String date;
  String type;

  CoinTransaction({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.reason,
    required this.date,
    this.type = 'earned',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'amount': amount,
    'reason': reason,
    'date': date,
    'type': type,
  };

  factory CoinTransaction.fromMap(Map<String, dynamic> m) => CoinTransaction(
    id: m['id'],
    studentId: m['studentId'],
    studentName: m['studentName'],
    amount: m['amount'],
    reason: m['reason'],
    date: m['date'],
    type: m['type'] ?? 'earned',
  );
}