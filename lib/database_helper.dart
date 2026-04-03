import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hasaty_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String file) async {
    final path = join(await getDatabasesPath(), file);
    return await openDatabase(path, version: 5, onCreate: _create, onUpgrade: _upgrade);
  }

  Future _create(Database db, int v) async {
    await db.execute('''CREATE TABLE students(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      groupName TEXT,
      balance REAL DEFAULT 0,
      xp INTEGER DEFAULT 0,
      coins INTEGER DEFAULT 0,
      archived INTEGER DEFAULT 0,
      joinDate TEXT
    )''');
    await db.execute('''CREATE TABLE groups(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      monthlyPrice REAL DEFAULT 0,
      days TEXT DEFAULT "",
      time TEXT DEFAULT ""
    )''');
    await db.execute('''CREATE TABLE subscriptions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      studentId INTEGER,
      groupId INTEGER,
      studentName TEXT,
      groupName TEXT,
      month INTEGER,
      year INTEGER,
      amount REAL,
      status TEXT DEFAULT "unpaid",
      paidAmount REAL DEFAULT 0,
      paidDate TEXT
    )''');
    await db.execute('''CREATE TABLE payments(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      studentId INTEGER,
      studentName TEXT,
      amount REAL,
      date TEXT,
      note TEXT,
      type TEXT DEFAULT "charge"
    )''');
    await db.execute('''CREATE TABLE attendance(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      studentId INTEGER,
      studentName TEXT,
      groupName TEXT,
      date TEXT,
      present INTEGER
    )''');
    await db.execute('''CREATE TABLE grades(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      studentId INTEGER,
      studentName TEXT,
      groupName TEXT,
      type TEXT,
      grade TEXT,
      score INTEGER DEFAULT 0,
      note TEXT,
      date TEXT,
      sessionTopic TEXT
    )''');
    await db.execute('''CREATE TABLE coin_transactions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      studentId INTEGER,
      studentName TEXT,
      amount INTEGER,
      reason TEXT,
      date TEXT,
      type TEXT DEFAULT "earned"
    )''');
    await db.execute('''CREATE TABLE notifications(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      body TEXT,
      type TEXT,
      date TEXT,
      isRead INTEGER DEFAULT 0,
      studentId INTEGER
    )''');
    await db.execute('''CREATE TABLE student_achievements(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      studentId INTEGER,
      achievementId TEXT,
      date TEXT
    )''');
  }

  Future _upgrade(Database db, int old, int nv) async {
    // ترقية تدريجي — نضيف الجداول الناقصة فقط
    if (old < 2) {
      await _safeExec(db, 'CREATE TABLE IF NOT EXISTS payments(id INTEGER PRIMARY KEY AUTOINCREMENT, studentId INTEGER, studentName TEXT, amount REAL, date TEXT, note TEXT, type TEXT DEFAULT "charge")');
      await _safeExec(db, 'CREATE TABLE IF NOT EXISTS attendance(id INTEGER PRIMARY KEY AUTOINCREMENT, studentId INTEGER, studentName TEXT, groupName TEXT, date TEXT, present INTEGER)');
    }
    if (old < 3) {
      await _safeExec(db, 'CREATE TABLE IF NOT EXISTS subscriptions(id INTEGER PRIMARY KEY AUTOINCREMENT, studentId INTEGER, groupId INTEGER, studentName TEXT, groupName TEXT, month INTEGER, year INTEGER, amount REAL, status TEXT DEFAULT "unpaid", paidAmount REAL DEFAULT 0, paidDate TEXT)');
      await _safeExec(db, 'ALTER TABLE groups ADD COLUMN days TEXT DEFAULT ""');
      await _safeExec(db, 'ALTER TABLE groups ADD COLUMN time TEXT DEFAULT ""');
      await _safeExec(db, 'ALTER TABLE students ADD COLUMN archived INTEGER DEFAULT 0');
      await _safeExec(db, 'ALTER TABLE students ADD COLUMN joinDate TEXT');
    }
    if (old < 4) {
      await _safeExec(db, 'CREATE TABLE IF NOT EXISTS grades(id INTEGER PRIMARY KEY AUTOINCREMENT, studentId INTEGER, studentName TEXT, groupName TEXT, type TEXT, grade TEXT, score INTEGER DEFAULT 0, note TEXT, date TEXT, sessionTopic TEXT)');
      await _safeExec(db, 'CREATE TABLE IF NOT EXISTS coin_transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, studentId INTEGER, studentName TEXT, amount INTEGER, reason TEXT, date TEXT, type TEXT DEFAULT "earned")');
      await _safeExec(db, 'CREATE TABLE IF NOT EXISTS notifications(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, body TEXT, type TEXT, date TEXT, isRead INTEGER DEFAULT 0, studentId INTEGER)');
      await _safeExec(db, 'ALTER TABLE students ADD COLUMN coins INTEGER DEFAULT 0');
    }
    if (old < 5) {
      await _safeExec(db, 'CREATE TABLE IF NOT EXISTS student_achievements(id INTEGER PRIMARY KEY AUTOINCREMENT, studentId INTEGER, achievementId TEXT, date TEXT)');
    }
  }

  Future _safeExec(Database db, String sql) async {
    try { await db.execute(sql); } catch (_) {}
  }

  String _today() {
    final n = DateTime.now();
    return '${n.day}/${n.month}/${n.year}';
  }

  // ========================= الطلاب =========================
  Future<int> addStudent(Student s) async =>
      (await database).insert('students', s.toMap());

  Future<List<Student>> getStudents({bool includeArchived = false}) async {
    final db = await database;
    final res = includeArchived
        ? await db.query('students', orderBy: 'xp DESC')
        : await db.query('students', where: 'archived = 0', orderBy: 'xp DESC');
    return res.map((e) => Student.fromMap(e)).toList();
  }

  Future<Student?> getStudentById(int id) async {
    final res = await (await database).query('students', where: 'id = ?', whereArgs: [id]);
    return res.isEmpty ? null : Student.fromMap(res.first);
  }

  Future<int> updateStudent(Student s) async =>
      (await database).update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);

  Future archiveStudent(int id) async =>
      (await database).update('students', {'archived': 1}, where: 'id = ?', whereArgs: [id]);

  Future restoreStudent(int id) async =>
      (await database).update('students', {'archived': 0}, where: 'id = ?', whereArgs: [id]);

  Future<List<Student>> getArchivedStudents() async {
    final res = await (await database).query('students', where: 'archived = 1', orderBy: 'name ASC');
    return res.map((e) => Student.fromMap(e)).toList();
  }

  Future<List<Student>> getStudentsWithDebt() async {
    final res = await (await database).query('students', where: 'balance < 0 AND archived = 0', orderBy: 'balance ASC');
    return res.map((e) => Student.fromMap(e)).toList();
  }

  Future chargeStudent(Student s, double amount, String note) async {
    s.balance += amount;
    if (s.balance >= 0) s.xp += 5;
    await updateStudent(s);
    await addPayment(Payment(studentId: s.id!, studentName: s.name, amount: amount, date: _today(), note: note, type: 'charge'));
    await _checkAchievements(s);
  }

  // ========================= المجموعات =========================
  Future<int> addGroup(Group g) async =>
      (await database).insert('groups', g.toMap());

  Future<List<Group>> getGroups() async {
    final res = await (await database).query('groups');
    return res.map((e) => Group.fromMap(e)).toList();
  }

  Future updateGroup(Group g) async =>
      (await database).update('groups', g.toMap(), where: 'id = ?', whereArgs: [g.id]);

  Future<int> deleteGroup(int id) async =>
      (await database).delete('groups', where: 'id = ?', whereArgs: [id]);

  // ========================= الاشتراكات =========================
  Future<int> addSubscription(Subscription s) async =>
      (await database).insert('subscriptions', s.toMap());

  Future<List<Subscription>> getSubscriptions({int? month, int? year, int? studentId}) async {
    final db = await database;
    String? where; List<dynamic>? args;
    if (month != null && year != null) { where = 'month = ? AND year = ?'; args = [month, year]; }
    else if (studentId != null) { where = 'studentId = ?'; args = [studentId]; }
    final res = await db.query('subscriptions', where: where, whereArgs: args, orderBy: 'year DESC, month DESC');
    return res.map((e) => Subscription.fromMap(e)).toList();
  }

  Future<bool> subscriptionExists(int studentId, int groupId, int month, int year) async {
    final res = await (await database).query('subscriptions',
        where: 'studentId = ? AND groupId = ? AND month = ? AND year = ?',
        whereArgs: [studentId, groupId, month, year]);
    return res.isNotEmpty;
  }

  Future<Map<String, int>> runMonthlyEngine(int month, int year) async {
    final students = await getStudents();
    final groups = await getGroups();
    int created = 0, skipped = 0;
    for (final s in students) {
      try {
        final group = groups.firstWhere((g) => g.name == s.groupName);
        if (group.id == null) { skipped++; continue; }
        final exists = await subscriptionExists(s.id!, group.id!, month, year);
        if (exists) { skipped++; continue; }
        double amount = group.monthlyPrice;
        // حساب نسبي للطلاب الجدد في منتصف الشهر
        if (s.joinDate.isNotEmpty) {
          try {
            final parts = s.joinDate.split('/');
            final joinDay = int.parse(parts[0]);
            final joinMonth = int.parse(parts[1]);
            final joinYear = int.parse(parts[2]);
            if (joinYear == year && joinMonth == month && joinDay > 15) amount = amount / 2;
          } catch (_) {}
        }
        await addSubscription(Subscription(
          studentId: s.id!, groupId: group.id!,
          studentName: s.name, groupName: group.name,
          month: month, year: year, amount: amount,
        ));
        s.balance -= amount;
        await updateStudent(s);
        created++;
      } catch (_) { skipped++; }
    }
    return {'created': created, 'skipped': skipped};
  }

  Future paySubscription(Subscription sub, double amount, Student student) async {
    final paid = amount > sub.remainingAmount ? sub.remainingAmount : amount;
    sub.paidAmount += paid;
    sub.status = sub.paidAmount >= sub.amount ? 'paid' : 'partial';
    sub.paidDate = _today();
    await (await database).update('subscriptions', sub.toMap(), where: 'id = ?', whereArgs: [sub.id]);
    student.balance += paid;
    await updateStudent(student);
    await addPayment(Payment(studentId: student.id!, studentName: student.name, amount: paid, date: _today(), note: 'اشتراك ${_monthName(sub.month)} ${sub.year}', type: 'subscription'));
    await _checkAchievements(student);
  }

  String _monthName(int m) {
    const months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return m >= 1 && m <= 12 ? months[m] : '';
  }

  // ========================= الدفعات =========================
  Future<int> addPayment(Payment p) async =>
      (await database).insert('payments', p.toMap());

  Future<List<Payment>> getAllPayments() async {
    final res = await (await database).query('payments', orderBy: 'id DESC');
    return res.map((e) => Payment.fromMap(e)).toList();
  }

  Future<List<Payment>> getStudentPayments(int studentId) async {
    final res = await (await database).query('payments',
        where: 'studentId = ?', whereArgs: [studentId], orderBy: 'id DESC');
    return res.map((e) => Payment.fromMap(e)).toList();
  }

  Future<double> getTotalCollectedThisMonth() async {
    final now = DateTime.now();
    final suffix = '/${now.month}/${now.year}';
    final all = await getAllPayments();
    return all.where((p) => p.date.endsWith(suffix)).fold(0.0, (s, p) => s + p.amount);
  }

  // ========================= الحضور =========================
  Future addAttendance(AttendanceRecord a) async =>
      (await database).insert('attendance', a.toMap());

  Future<List<AttendanceRecord>> getStudentAttendance(int studentId) async {
    final res = await (await database).query('attendance',
        where: 'studentId = ?', whereArgs: [studentId], orderBy: 'id DESC');
    return res.map((e) => AttendanceRecord.fromMap(e)).toList();
  }

  Future<double> getAttendancePercentage(int studentId) async {
    final r = await getStudentAttendance(studentId);
    if (r.isEmpty) return 0;
    return r.where((x) => x.present).length / r.length * 100;
  }

  Future<Map<String, dynamic>> markAttendanceByQR(int studentId, String groupName, double price) async {
    final student = await getStudentById(studentId);
    if (student == null) return {'success': false, 'message': 'الطالب غير موجود'};
    final today = _today();
    final db = await database;
    final existing = await db.query('attendance',
        where: 'studentId = ? AND date = ? AND groupName = ?', whereArgs: [studentId, today, groupName]);
    if (existing.isNotEmpty) return {'success': false, 'message': 'تم تسجيل ${student.name} اليوم مسبقاً', 'student': student};
    await addAttendance(AttendanceRecord(studentId: student.id!, studentName: student.name, groupName: groupName, date: today, present: true));
    student.balance -= price;
    student.xp += 10;
    await updateStudent(student);
    await _checkAchievements(student);
    return {'success': true, 'message': 'أهلاً ${student.name}! ✅', 'student': student};
  }

  // ========================= التقييم الأكاديمي =========================
  Future<int> addGrade(AcademicGrade g) async =>
      (await database).insert('grades', g.toMap());

  Future<List<AcademicGrade>> getAllGrades() async {
    final res = await (await database).query('grades', orderBy: 'id DESC');
    return res.map((e) => AcademicGrade.fromMap(e)).toList();
  }

  Future<List<AcademicGrade>> getStudentGrades(int studentId) async {
    final res = await (await database).query('grades',
        where: 'studentId = ?', whereArgs: [studentId], orderBy: 'id DESC');
    return res.map((e) => AcademicGrade.fromMap(e)).toList();
  }

  Future<Map<String, dynamic>> getStudentAcademicSummary(int studentId) async {
    final grades = await getStudentGrades(studentId);
    if (grades.isEmpty) return {'total': 0, 'excellent': 0, 'weak': 0, 'average': 0.0};
    return {
      'total': grades.length,
      'excellent': grades.where((g) => g.grade == 'excellent').length,
      'weak': grades.where((g) => g.grade == 'weak').length,
      'average': grades.fold(0.0, (s, g) => s + g.score) / grades.length,
    };
  }

  Future<List<Student>> getUnderperformingStudents() async {
    final students = await getStudents();
    final result = <Student>[];
    for (final s in students) {
      final grades = await getStudentGrades(s.id!);
      final weakCount = grades.where((g) => g.grade == 'weak').length;
      final pct = await getAttendancePercentage(s.id!);
      if (weakCount >= 2 || pct < 50) result.add(s);
    }
    return result;
  }

  // ========================= عملة نصر =========================
  Future awardCoins(int studentId, String studentName, int amount, String reason) async {
    final db = await database;
    await db.rawUpdate('UPDATE students SET coins = COALESCE(coins, 0) + ? WHERE id = ?', [amount, studentId]);
    await db.insert('coin_transactions', {'studentId': studentId, 'studentName': studentName, 'amount': amount, 'reason': reason, 'date': _today(), 'type': 'earned'});
  }

  Future spendCoins(int studentId, String studentName, int amount, String reason) async {
    final db = await database;
    await db.rawUpdate('UPDATE students SET coins = COALESCE(coins, 0) - ? WHERE id = ?', [amount, studentId]);
    await db.insert('coin_transactions', {'studentId': studentId, 'studentName': studentName, 'amount': -amount, 'reason': reason, 'date': _today(), 'type': 'spent'});
  }

  Future<int> getStudentCoins(int studentId) async {
    final res = await (await database).query('students', columns: ['coins'], where: 'id = ?', whereArgs: [studentId]);
    return res.isEmpty ? 0 : (res.first['coins'] as int? ?? 0);
  }

  // ========================= الإشعارات =========================
  Future addNotification(AppNotification n) async =>
      (await database).insert('notifications', n.toMap());

  Future<List<AppNotification>> getNotifications() async {
    final res = await (await database).query('notifications', orderBy: 'id DESC', limit: 100);
    return res.map((e) => AppNotification.fromMap(e)).toList();
  }

  Future<int> getUnreadCount() async {
    final res = await (await database).query('notifications', where: 'isRead = 0');
    return res.length;
  }

  Future markAllRead() async =>
      (await database).update('notifications', {'isRead': 1});

  Future generateSmartNotifications() async {
    final students = await getStudents();
    final today = _today();
    for (final s in students) {
      final pct = await getAttendancePercentage(s.id!);
      if (s.balance < -200) {
        await addNotification(AppNotification(title: 'دين متراكم — ${s.name}', body: 'رصيد ${s.name} أصبح ${s.balance.toStringAsFixed(0)} ج.م', type: 'debt', date: today, studentId: s.id));
      }
      if (pct < 50 && pct > 0) {
        await addNotification(AppNotification(title: 'غياب متكرر — ${s.name}', body: 'نسبة حضور ${s.name} انخفضت إلى ${pct.toStringAsFixed(0)}%', type: 'absence', date: today, studentId: s.id));
      }
    }
  }

  // ========================= الإنجازات =========================
  Future<List<String>> getStudentAchievements(int studentId) async {
    final res = await (await database).query('student_achievements', where: 'studentId = ?', whereArgs: [studentId]);
    return res.map((e) => e['achievementId'] as String).toList();
  }

  Future _grant(int studentId, String achievementId) async {
    final db = await database;
    final ex = await db.query('student_achievements', where: 'studentId = ? AND achievementId = ?', whereArgs: [studentId, achievementId]);
    if (ex.isEmpty) await db.insert('student_achievements', {'studentId': studentId, 'achievementId': achievementId, 'date': _today()});
  }

  Future _checkAchievements(Student s) async {
    if (s.xp >= 50)  await _grant(s.id!, 'xp_50');
    if (s.xp >= 200) await _grant(s.id!, 'xp_200');
    if (s.xp >= 500) await _grant(s.id!, 'xp_500');
    if (s.balance >= 0) await _grant(s.id!, 'regular_payment');
    final records = await getStudentAttendance(s.id!);
    if (records.length >= 10 && records.take(10).every((r) => r.present)) await _grant(s.id!, 'attend_10');
    final subs = await getSubscriptions(studentId: s.id!);
    if (subs.where((x) => x.status == 'paid').length >= 3) await _grant(s.id!, 'sub_paid_3');
  }

  // ========================= التقارير الذكية =========================
  Future<Map<String, dynamic>> getSmartReport() async {
    final students = await getStudents();
    final payments = await getAllPayments();
    final now = DateTime.now();
    final suffix = '/${now.month}/${now.year}';
    final monthlyPayments = payments.where((p) => p.date.endsWith(suffix)).toList();

    final stats = <Map<String, dynamic>>[];
    for (final s in students) {
      final pct = await getAttendancePercentage(s.id!);
      stats.add({'student': s, 'percentage': pct});
    }
    stats.sort((a, b) => (b['percentage'] as double).compareTo(a['percentage'] as double));

    final debtStudents = students.where((s) => s.balance < 0).toList();
    final subs = await getSubscriptions(month: now.month, year: now.year);
    final expectedIncome = subs.fold(0.0, (s, x) => s + x.amount);
    final actualIncome = monthlyPayments.fold(0.0, (s, p) => s + p.amount);

    final riskStudents = <Map<String, dynamic>>[];
    for (final entry in stats) {
      final s = entry['student'] as Student;
      final pct = entry['percentage'] as double;
      final risk = s.riskLevel(pct);
      if (risk != 'ملتزم') riskStudents.add({'student': s, 'risk': risk, 'attendance': pct});
    }

    return {
      'bestAttendance': stats.take(3).toList(),
      'mostAbsent': stats.reversed.take(3).toList(),
      'monthlyIncome': actualIncome,
      'expectedIncome': expectedIncome,
      'collectionRate': expectedIncome > 0 ? actualIncome / expectedIncome * 100 : 0.0,
      'debtStudents': debtStudents,
      'totalDebt': debtStudents.fold(0.0, (s, st) => s + st.balance.abs()),
      'weekStar': students.isNotEmpty ? students.first : null,
      'totalStudents': students.length,
      'monthlyPaymentsCount': monthlyPayments.length,
      'riskStudents': riskStudents,
    };
  }
}
