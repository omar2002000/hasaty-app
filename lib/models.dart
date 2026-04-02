// lib/models.dart
// هذا الملف يحتوي على جميع النماذج - لا تحتاج لأي ملفات أخرى في مجلد models

import 'dart:convert';

// ====================== الطالب ======================
class Student {
  int? id;
  String name, phone, groupName;
  double balance;
  int xp;
  int coins;
  bool archived;
  String joinDate;

  Student({
    this.id,
    required this.name,
    required this.phone,
    required this.groupName,
    this.balance = 0.0,
    this.xp = 0,
    this.coins = 0,
    this.archived = false,
    String? joinDate,
  }) : joinDate = joinDate ?? _today();

  static String _today() {
    final n = DateTime.now();
    return '${n.day}/${n.month}/${n.year}';
  }

  String get level {
    if (xp >= 500) return 'نجم';
    if (xp >= 200) return 'متقدم';
    if (xp >= 50) return 'متوسط';
    return 'مبتدئ';
  }

  String get levelEmoji {
    if (xp >= 500) return '⭐';
    if (xp >= 200) return '🔥';
    if (xp >= 50) return '📈';
    return '🌱';
  }

  int get nextLevelXp {
    if (xp >= 500) return 500;
    if (xp >= 200) return 500;
    if (xp >= 50) return 200;
    return 50;
  }

  String riskLevel(double attendancePct) {
    if (attendancePct >= 75 && balance >= 0) return 'ملتزم';
    if (attendancePct >= 50 && balance >= -200) return 'متأخر';
    return 'خطر';
  }

  bool canSpend(int amount) => coins >= amount;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'groupName': groupName,
    'balance': balance,
    'xp': xp,
    'coins': coins,
    'archived': archived ? 1 : 0,
    'joinDate': joinDate,
  };

  factory Student.fromMap(Map<String, dynamic> m) => Student(
    id: m['id'],
    name: m['name'],
    phone: m['phone'],
    groupName: m['groupName'],
    balance: (m['balance'] ?? 0).toDouble(),
    xp: m['xp'] ?? 0,
    coins: m['coins'] ?? 0,
    archived: (m['archived'] ?? 0) == 1,
    joinDate: m['joinDate'] ?? '',
  );
}

// ====================== المجموعة ======================
class Group {
  int? id;
  String name;
  double monthlyPrice;
  String days;
  String time;

  Group({
    this.id,
    required this.name,
    required this.monthlyPrice,
    this.days = '',
    this.time = '',
  });

  double get price => monthlyPrice;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'monthlyPrice': monthlyPrice,
    'days': days,
    'time': time,
  };

  factory Group.fromMap(Map<String, dynamic> m) => Group(
    id: m['id'],
    name: m['name'],
    monthlyPrice: (m['monthlyPrice'] ?? 0).toDouble(),
    days: m['days'] ?? '',
    time: m['time'] ?? '',
  );
}

// ====================== الاشتراك ======================
class Subscription {
  int? id;
  int studentId, groupId, month, year;
  String studentName, groupName;
  double amount, paidAmount;
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

// ====================== الدفعة ======================
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

// ====================== الحضور ======================
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

// ====================== التقييم الأكاديمي ======================
class AcademicGrade {
  int? id;
  int studentId;
  String studentName;
  String groupName;
  String type;
  String grade;
  int score;
  String note;
  String date;
  String sessionTopic;

  AcademicGrade({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.groupName,
    required this.type,
    required this.grade,
    this.score = 0,
    this.note = '',
    required this.date,
    this.sessionTopic = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'groupName': groupName,
    'type': type,
    'grade': grade,
    'score': score,
    'note': note,
    'date': date,
    'sessionTopic': sessionTopic,
  };

  factory AcademicGrade.fromMap(Map<String, dynamic> m) => AcademicGrade(
    id: m['id'],
    studentId: m['studentId'],
    studentName: m['studentName'],
    groupName: m['groupName'],
    type: m['type'],
    grade: m['grade'],
    score: m['score'] ?? 0,
    note: m['note'] ?? '',
    date: m['date'],
    sessionTopic: m['sessionTopic'] ?? '',
  );
}

// ====================== سجل التقييم ======================
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

// ====================== العملات ======================
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

// ====================== الإشعارات ======================
class AppNotification {
  int? id;
  String title, body, type, date;
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

// ====================== الإنجازات ======================
class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String condition;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.condition,
  });
}

class Achievements {
  static List<Achievement> all = [
    const Achievement(
      id: 'xp_50',
      title: 'بداية موفقة',
      description: 'تجميع 50 نقطة XP',
      emoji: '🌱',
      condition: '50 نقطة XP',
    ),
    const Achievement(
      id: 'xp_200',
      title: 'متقدم',
      description: 'تجميع 200 نقطة XP',
      emoji: '📈',
      condition: '200 نقطة XP',
    ),
    const Achievement(
      id: 'xp_500',
      title: 'نجم حصتي',
      description: 'تجميع 500 نقطة XP',
      emoji: '⭐',
      condition: '500 نقطة XP',
    ),
    const Achievement(
      id: 'regular_payment',
      title: 'منتظم',
      description: 'السداد المنتظم للاشتراكات',
      emoji: '💰',
      condition: 'الرصيد موجب',
    ),
    const Achievement(
      id: 'attend_10',
      title: 'حضور مثالي',
      description: 'حضور 10 حصص متتالية',
      emoji: '🎯',
      condition: '10 حصص حضور متتالية',
    ),
    const Achievement(
      id: 'sub_paid_3',
      title: 'ملتزم مادياً',
      description: 'سداد 3 اشتراكات شهرية كاملة',
      emoji: '💎',
      condition: '3 اشتراكات مدفوعة',
    ),
  ];

  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ====================== قوالب واتساب ======================
class WhatsAppTemplate {
  final String id, title, emoji;
  final String Function(Map<String, String>) buildMessage;

  const WhatsAppTemplate({
    required this.id,
    required this.title,
    required this.emoji,
    required this.buildMessage,
  });
}

class WhatsAppTemplates {
  static List<WhatsAppTemplate> all = [
    WhatsAppTemplate(
      id: 'debt',
      title: 'تذكير بالديون',
      emoji: '💰',
      buildMessage: (p) =>
          'أهلاً ولي أمر ${p['name']}،\nيرجى العلم بأن المبلغ المستحق عليكم هو ${p['amount']} ج.م.\nمعلمك: مستر نصر علي',
    ),
    WhatsAppTemplate(
      id: 'absence',
      title: 'إشعار غياب',
      emoji: '📵',
      buildMessage: (p) =>
          'أهلاً ولي أمر ${p['name']}،\nنود إعلامكم بأن الطالب تغيب عن حصة ${p['group']}.\nمعلمك: مستر نصر علي',
    ),
    WhatsAppTemplate(
      id: 'monthly_report',
      title: 'تقرير شهري',
      emoji: '📊',
      buildMessage: (p) =>
          'أهلاً ولي أمر ${p['name']}،\nتقرير أداء الطالب لشهر ${p['month']}:\nالحضور: ${p['attendance']}%\nالرصيد: ${p['balance']} ج\nنقاط XP: ${p['xp']}\nمعلمك: مستر نصر علي',
    ),
    WhatsAppTemplate(
      id: 'excellence',
      title: 'تهنئة متفوقين',
      emoji: '🏆',
      buildMessage: (p) =>
          'أهلاً ولي أمر ${p['name']}،\nنبارك لكم تفوق الطالب وحصوله على مستوى ${p['level']}!\nمعلمك: مستر نصر علي',
    ),
    WhatsAppTemplate(
      id: 'grade_weak',
      title: 'تنبيه أكاديمي',
      emoji: '⚠️',
      buildMessage: (p) =>
          'أهلاً ولي أمر ${p['name']}،\nنود لفت انتباهكم إلى أن الطالب حصل على تقدير ${p['grade']} في ${p['type']}.\nمعلمك: مستر نصر علي',
    ),
  ];
}