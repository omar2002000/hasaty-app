// ============================================================
// models.dart — النماذج الموحدة الكاملة لتطبيق حصتي v4
// ============================================================

String _todayStr() {
  final n = DateTime.now();
  return '${n.day}/${n.month}/${n.year}';
}

// ========================= الطالب =========================
class Student {
  int? id;
  String name, phone, groupName;
  double balance;
  int xp, coins;
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
  }) : joinDate = joinDate ?? _todayStr();

  String get level {
    if (xp >= 500) return 'نجم';
    if (xp >= 200) return 'متقدم';
    if (xp >= 50)  return 'متوسط';
    return 'مبتدئ';
  }
  String get levelEmoji {
    if (xp >= 500) return '⭐';
    if (xp >= 200) return '🔥';
    if (xp >= 50)  return '📈';
    return '🌱';
  }
  int get nextLevelXp {
    if (xp >= 500) return 500;
    if (xp >= 200) return 500;
    if (xp >= 50)  return 200;
    return 50;
  }

  String riskLevel(double attendancePct) {
    if (attendancePct >= 75 && balance >= 0) return 'ملتزم';
    if (attendancePct >= 50 && balance >= -200) return 'متأخر';
    return 'خطر';
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'phone': phone, 'groupName': groupName,
    'balance': balance, 'xp': xp, 'coins': coins,
    'archived': archived ? 1 : 0, 'joinDate': joinDate,
  };

  factory Student.fromMap(Map<String, dynamic> m) => Student(
    id: m['id'], name: m['name'] ?? '', phone: m['phone'] ?? '',
    groupName: m['groupName'] ?? '', balance: (m['balance'] ?? 0).toDouble(),
    xp: m['xp'] ?? 0, coins: m['coins'] ?? 0,
    archived: (m['archived'] ?? 0) == 1, joinDate: m['joinDate'] ?? _todayStr(),
  );
}

// ========================= المجموعة =========================
class Group {
  int? id;
  String name, days, time;
  double monthlyPrice;

  Group({this.id, required this.name, required this.monthlyPrice, this.days = '', this.time = ''});

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'monthlyPrice': monthlyPrice, 'days': days, 'time': time,
  };

  factory Group.fromMap(Map<String, dynamic> m) => Group(
    id: m['id'], name: m['name'] ?? '',
    monthlyPrice: (m['monthlyPrice'] ?? m['price'] ?? 0).toDouble(),
    days: m['days'] ?? '', time: m['time'] ?? '',
  );
}

// ========================= الاشتراك الشهري =========================
class Subscription {
  int? id;
  int studentId, groupId, month, year;
  String studentName, groupName;
  double amount, paidAmount;
  String status; // unpaid / partial / paid
  String? paidDate;

  Subscription({
    this.id, required this.studentId, required this.groupId,
    required this.studentName, required this.groupName,
    required this.month, required this.year, required this.amount,
    this.status = 'unpaid', this.paidAmount = 0, this.paidDate,
  });

  double get remainingAmount => amount - paidAmount;
  bool get isPaid => status == 'paid';

  String get statusLabel {
    switch (status) {
      case 'paid':    return 'مدفوع';
      case 'partial': return 'جزئي';
      default:        return 'غير مدفوع';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'studentId': studentId, 'groupId': groupId,
    'studentName': studentName, 'groupName': groupName,
    'month': month, 'year': year, 'amount': amount,
    'status': status, 'paidAmount': paidAmount, 'paidDate': paidDate,
  };

  factory Subscription.fromMap(Map<String, dynamic> m) => Subscription(
    id: m['id'], studentId: m['studentId'], groupId: m['groupId'],
    studentName: m['studentName'] ?? '', groupName: m['groupName'] ?? '',
    month: m['month'], year: m['year'], amount: (m['amount'] ?? 0).toDouble(),
    status: m['status'] ?? 'unpaid', paidAmount: (m['paidAmount'] ?? 0).toDouble(),
    paidDate: m['paidDate'],
  );
}

// ========================= الدفعة =========================
class Payment {
  int? id;
  int studentId;
  String studentName, date, note, type;
  double amount;

  Payment({
    this.id, required this.studentId, required this.studentName,
    required this.amount, required this.date, this.note = '', this.type = 'charge',
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'studentId': studentId, 'studentName': studentName,
    'amount': amount, 'date': date, 'note': note, 'type': type,
  };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
    id: m['id'], studentId: m['studentId'], studentName: m['studentName'] ?? '',
    amount: (m['amount'] ?? 0).toDouble(), date: m['date'] ?? '',
    note: m['note'] ?? '', type: m['type'] ?? 'charge',
  );
}

// ========================= الحضور =========================
class AttendanceRecord {
  int? id;
  int studentId;
  String studentName, groupName, date;
  bool present;

  AttendanceRecord({
    this.id, required this.studentId, required this.studentName,
    required this.groupName, required this.date, required this.present,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'studentId': studentId, 'studentName': studentName,
    'groupName': groupName, 'date': date, 'present': present ? 1 : 0,
  };

  factory AttendanceRecord.fromMap(Map<String, dynamic> m) => AttendanceRecord(
    id: m['id'], studentId: m['studentId'], studentName: m['studentName'] ?? '',
    groupName: m['groupName'] ?? '', date: m['date'] ?? '',
    present: (m['present'] ?? 0) == 1,
  );
}

// ========================= التقييم الأكاديمي =========================
class AcademicGrade {
  int? id;
  int studentId;
  String studentName, groupName, type, grade, note, date, sessionTopic;
  int score;

  AcademicGrade({
    this.id, required this.studentId, required this.studentName,
    required this.groupName, required this.type, required this.grade,
    this.score = 0, this.note = '', required this.date, this.sessionTopic = '',
  });

  String get typeLabel {
    switch (type) {
      case 'recitation': return 'تسميع';
      case 'homework':   return 'واجب';
      case 'exam':       return 'اختبار';
      default: return type;
    }
  }
  String get gradeLabel {
    switch (grade) {
      case 'excellent':  return 'ممتاز';
      case 'good':       return 'جيد';
      case 'acceptable': return 'مقبول';
      case 'weak':       return 'ضعيف';
      default: return grade;
    }
  }
  String get gradeEmoji {
    switch (grade) {
      case 'excellent':  return '🌟';
      case 'good':       return '✅';
      case 'acceptable': return '⚠️';
      case 'weak':       return '❌';
      default: return '📝';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'studentId': studentId, 'studentName': studentName,
    'groupName': groupName, 'type': type, 'grade': grade, 'score': score,
    'note': note, 'date': date, 'sessionTopic': sessionTopic,
  };

  factory AcademicGrade.fromMap(Map<String, dynamic> m) => AcademicGrade(
    id: m['id'], studentId: m['studentId'], studentName: m['studentName'] ?? '',
    groupName: m['groupName'] ?? '', type: m['type'] ?? '', grade: m['grade'] ?? '',
    score: m['score'] ?? 0, note: m['note'] ?? '', date: m['date'] ?? '',
    sessionTopic: m['sessionTopic'] ?? '',
  );
}

// ========================= عملة نصر =========================
class CoinTransaction {
  int? id;
  int studentId, amount;
  String studentName, reason, date, type;

  CoinTransaction({
    this.id, required this.studentId, required this.studentName,
    required this.amount, required this.reason, required this.date, this.type = 'earned',
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'studentId': studentId, 'studentName': studentName,
    'amount': amount, 'reason': reason, 'date': date, 'type': type,
  };

  factory CoinTransaction.fromMap(Map<String, dynamic> m) => CoinTransaction(
    id: m['id'], studentId: m['studentId'], studentName: m['studentName'] ?? '',
    amount: m['amount'] ?? 0, reason: m['reason'] ?? '', date: m['date'] ?? '',
    type: m['type'] ?? 'earned',
  );
}

// ========================= الإشعار =========================
class AppNotification {
  int? id;
  int? studentId;
  String title, body, type, date;
  bool isRead;

  AppNotification({
    this.id, required this.title, required this.body, required this.type,
    required this.date, this.isRead = false, this.studentId,
  });

  String get typeIcon {
    switch (type) {
      case 'debt':       return '💰';
      case 'absence':    return '📵';
      case 'excellence': return '🏆';
      case 'risk':       return '⚠️';
      default:           return '🔔';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'body': body, 'type': type,
    'date': date, 'isRead': isRead ? 1 : 0, 'studentId': studentId,
  };

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
    id: m['id'], title: m['title'] ?? '', body: m['body'] ?? '',
    type: m['type'] ?? 'general', date: m['date'] ?? '',
    isRead: (m['isRead'] ?? 0) == 1, studentId: m['studentId'],
  );
}

// ========================= الإنجازات =========================
class Achievement {
  final String id, title, emoji, description;
  const Achievement({required this.id, required this.title, required this.emoji, required this.description});
}

class Achievements {
  static const List<Achievement> all = [
    Achievement(id: 'no_absence_month', title: 'لم يتغيب شهراً',   emoji: '🏅', description: 'حضر كل الحصص خلال شهر'),
    Achievement(id: 'regular_payment',  title: 'ملتزم مالياً',     emoji: '💎', description: 'رصيده دائماً إيجابي'),
    Achievement(id: 'xp_50',           title: 'بداية ممتازة',     emoji: '🌱', description: 'وصل إلى 50 XP'),
    Achievement(id: 'xp_200',          title: 'طالب متقدم',       emoji: '🔥', description: 'وصل إلى 200 XP'),
    Achievement(id: 'xp_500',          title: 'نجم الفصل',        emoji: '⭐', description: 'وصل إلى 500 XP'),
    Achievement(id: 'attend_10',        title: '10 حصص',           emoji: '🎯', description: '10 حضور متتالي'),
    Achievement(id: 'sub_paid_3',       title: '3 أشهر ملتزم',    emoji: '🏆', description: 'دفع 3 اشتراكات متتالية'),
  ];

  static Achievement? getById(String id) {
    try { return all.firstWhere((a) => a.id == id); } catch (_) { return null; }
  }
}

// ========================= قوالب واتساب =========================
class WhatsAppTemplates {
  static String absence(String name, String group) =>
    'أهلاً ولي أمر $name،\nنُعلمكم بأن نجلكم *$name* لم يحضر حصة اليوم بمجموعة $group.\nيُرجى التواصل معنا.\nمعلمكم: مستر نصر علي 📚';

  static String debt(String name, String amount) =>
    'أهلاً ولي أمر $name،\nنُذكّركم بأن المبلغ المستحق على نجلكم *$name* هو *$amount ج.م*.\nيُرجى السداد في أقرب وقت.\nشكراً لتعاونكم 🙏\nمعلمكم: مستر نصر علي';

  static String gradeResult(String name, String grade, String type) =>
    '*${grade == 'ممتاز' || grade == 'جيد' ? '🌟 مبروك!' : '⚠️ تنبيه:'}*\nأهلاً ولي أمر $name،\nحصل نجلكم *$name* على تقدير *$grade* في $type اليوم.\n${grade == 'ممتاز' || grade == 'جيد' ? 'استمرار موفق 💪' : 'يُرجى متابعة المذاكرة معه.'}\nمعلمكم: مستر نصر علي';

  static String monthlyReport(String name, String month, String attendance, String balance, String xp) =>
    '📊 تقرير شهر $month:\nأهلاً ولي أمر $name،\nملخص أداء نجلكم *$name*:\n✅ الحضور: $attendance%\n💰 الرصيد: $balance ج.م\n⭐ النقاط: $xp XP\nمعلمكم: مستر نصر علي';

  static String excellence(String name, String level) =>
    '🏆 تهنئة خاصة!\nأهلاً ولي أمر $name،\nيسعدنا إبلاغكم بأن نجلكم *$name* وصل إلى مستوى *$level*!\nاستمر يا نجم ⭐\nمعلمكم: مستر نصر علي';
}
