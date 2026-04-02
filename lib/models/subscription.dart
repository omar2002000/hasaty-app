// lib/models/subscription.dart

class Subscription {
  int? id;
  int studentId;
  int groupId;
  int month;
  int year;
  String studentName;
  String groupName;
  double amount;
  double paidAmount;
  String status;
  String? paidDate;

  Subscription({
    this.id,
    required this.studentId,
    required this.groupId,
    required this.studentName,
    required this.groupName,
    required this.month,
    required this.year,
    required this.amount,
    this.paidAmount = 0,
    this.status = 'unpaid',
    this.paidDate,
  });

  double get remainingAmount => amount - paidAmount;
  
  String get statusLabel {
    if (status == 'paid') return 'مدفوع';
    if (status == 'partial') return 'جزئي';
    return 'غير مدفوع';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'groupId': groupId,
    'studentName': studentName,
    'groupName': groupName,
    'month': month,
    'year': year,
    'amount': amount,
    'paidAmount': paidAmount,
    'status': status,
    'paidDate': paidDate,
  };

  factory Subscription.fromMap(Map<String, dynamic> m) => Subscription(
    id: m['id'],
    studentId: m['studentId'],
    groupId: m['groupId'],
    studentName: m['studentName'],
    groupName: m['groupName'],
    month: m['month'],
    year: m['year'],
    amount: (m['amount'] ?? 0).toDouble(),
    paidAmount: (m['paidAmount'] ?? 0).toDouble(),
    status: m['status'] ?? 'unpaid',
    paidDate: m['paidDate'],
  );
}