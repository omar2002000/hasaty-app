// lib/database_helper.dart
// قاعدة بيانات تطبيق حصتي - مستر نصر علي

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/index.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hasaty_v5.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final path = join(await getDatabasesPath(), fileName);
    return await openDatabase(
      path,
      version: 5,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
  }

  Future<void> _create(Database db, int version) async {
    // ===== الجداول الأساسية =====
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        groupName TEXT,
        balance REAL DEFAULT 0,
        xp INTEGER DEFAULT 0,
        archived INTEGER DEFAULT 0,
        joinDate TEXT,
        coins INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE groups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        monthlyPrice REAL,
        days TEXT DEFAULT "",
        time TEXT DEFAULT ""
      )
    ''');

    await db.execute('''
      CREATE TABLE subscriptions(
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
      )
    ''');

    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER,
        studentName TEXT,
        amount REAL,
        date TEXT,
        note TEXT,
        type TEXT DEFAULT "charge"
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER,
        studentName TEXT,
        groupName TEXT,
        date TEXT,
        present INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE student_achievements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER,
        achievementId TEXT,
        date TEXT
      )
    ''');

    // ===== الجداول الجديدة =====
    await db.execute('''
      CREATE TABLE grades(
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
      )
    ''');

    await db.execute('''
      CREATE TABLE coin_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER,
        studentName TEXT,
        amount INTEGER,
        reason TEXT,
        date TEXT,
        type TEXT DEFAULT "earned"
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        body TEXT,
        type TEXT,
        date TEXT,
        isRead INTEGER DEFAULT 0,
        studentId INTEGER
      )
    ''');

    // ========== إضافة الفهارس (Indexes) لتحسين الأداء ==========
    await db.execute('CREATE INDEX idx_students_name ON students(name)');
    await db.execute('CREATE INDEX idx_students_group ON students(groupName)');
    await db.execute('CREATE INDEX idx_students_balance ON students(balance)');
    await db.execute('CREATE INDEX idx_students_xp ON students(xp)');
    await db.execute('CREATE INDEX idx_students_archived ON students(archived)');
    await db.execute('CREATE INDEX idx_payments_student ON payments(studentId)');
    await db.execute('CREATE INDEX idx_payments_date ON payments(date)');
    await db.execute('CREATE INDEX idx_attendance_student ON attendance(studentId)');
    await db.execute('CREATE INDEX idx_attendance_date ON attendance(date)');
    await db.execute('CREATE INDEX idx_subscriptions_student ON subscriptions(studentId)');
    await db.execute('CREATE INDEX idx_subscriptions_month ON subscriptions(month, year)');
    await db.execute('CREATE INDEX idx_grades_student ON grades(studentId)');
    await db.execute('CREATE INDEX idx_notifications_student ON notifications(studentId)');
    await db.execute('CREATE INDEX idx_coins_student ON coin_transactions(studentId)');
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE groups ADD COLUMN days TEXT DEFAULT ""');
      await db.execute('ALTER TABLE groups ADD COLUMN time TEXT DEFAULT ""');
      await db.execute('ALTER TABLE students ADD COLUMN archived INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE students ADD COLUMN joinDate TEXT DEFAULT ""');
      try {
        await db.execute('ALTER TABLE payments ADD COLUMN type TEXT DEFAULT "charge"');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS grades(
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
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS coin_transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          studentId INTEGER,
          studentName TEXT,
          amount INTEGER,
          reason TEXT,
          date TEXT,
          type TEXT DEFAULT "earned"
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          body TEXT,
          type TEXT,
          date TEXT,
          isRead INTEGER DEFAULT 0,
          studentId INTEGER
        )
      ''');

      try {
        await db.execute('ALTER TABLE students ADD COLUMN coins INTEGER DEFAULT 0');
      } catch (_) {}
    }
  }

  String _today() {
    final n = DateTime.now();
    return '${n.day}/${n.month}/${n.year}';
  }

  String _monthName(int m) {
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[m];
  }

  // ====================== الطلاب ======================
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
    final res = await (await database)
        .query('students', where: 'id = ?', whereArgs: [id]);
    return res.isEmpty ? null : Student.fromMap(res.first);
  }

  Future<int> updateStudent(Student s) async =>
      (await database).update('students', s.toMap(),
          where: 'id = ?', whereArgs: [s.id]);

  Future<void> archiveStudent(int id) async =>
      (await database).update('students', {'archived': 1},
          where: 'id = ?', whereArgs: [id]);

  Future<void> restoreStudent(int id) async =>
      (await database).update('students', {'archived': 0},
          where: 'id = ?', whereArgs: [id]);

  Future<List<Student>> getArchivedStudents() async {
    final res = await (await database)
        .query('students', where: 'archived = 1');
    return res.map((e) => Student.fromMap(e)).toList();
  }

  Future<void> chargeStudent(Student s, double amount, String note) async {
    s.balance += amount;
    if (s.balance >= 0) s.xp += 5;
    await updateStudent(s);
    await addPayment(Payment(
      studentId: s.id!,
      studentName: s.name,
      amount: amount,
      date: _today(),
      note: note,
      type: 'charge',
    ));
    await _checkAchievements(s);
  }

  // ====================== المجموعات ======================
  Future<int> addGroup(Group g) async =>
      (await database).insert('groups', g.toMap());

  Future<List<Group>> getGroups() async {
    final res = await (await database).query('groups');
    return res.map((e) => Group.fromMap(e)).toList();
  }

  Future<void> updateGroup(Group g) async =>
      (await database).update('groups', g.toMap(),
          where: 'id = ?', whereArgs: [g.id]);

  Future<int> deleteGroup(int id) async =>
      (await database).delete('groups', where: 'id = ?', whereArgs: [id]);

  // ====================== الاشتراكات ======================
  Future<int> addSubscription(Subscription s) async =>
      (await database).insert('subscriptions', s.toMap());

  Future<List<Subscription>> getSubscriptions(
      {int? month, int? year, int? studentId}) async {
    final db = await database;
    String? where;
    List<dynamic>? args;
    if (month != null && year != null) {
      where = 'month = ? AND year = ?';
      args = [month, year];
    } else if (studentId != null) {
      where = 'studentId = ?';
      args = [studentId];
    }
    final res = await db.query('subscriptions',
        where: where, whereArgs: args, orderBy: 'year DESC, month DESC');
    return res.map((e) => Subscription.fromMap(e)).toList();
  }

  Future<bool> subscriptionExists(
      int studentId, int groupId, int month, int year) async {
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
      final group = groups.firstWhere(
          (g) => g.name == s.groupName,
          orElse: () => Group(name: '', monthlyPrice: 0));
      if (group.id == null) {
        skipped++;
        continue;
      }

      final exists = await subscriptionExists(s.id!, group.id!, month, year);
      if (exists) {
        skipped++;
        continue;
      }

      double amount = group.monthlyPrice;
      if (s.joinDate.isNotEmpty) {
        try {
          final parts = s.joinDate.split('/');
          final joinDay = int.parse(parts[0]);
          final joinMonth = int.parse(parts[1]);
          final joinYear = int.parse(parts[2]);
          if (joinYear == year && joinMonth == month && joinDay > 15)
            amount /= 2;
        } catch (_) {}
      }

      await addSubscription(Subscription(
        studentId: s.id!,
        groupId: group.id!,
        studentName: s.name,
        groupName: group.name,
        month: month,
        year: year,
        amount: amount,
      ));
      s.balance -= amount;
      await updateStudent(s);
      created++;
    }
    return {'created': created, 'skipped': skipped};
  }

  Future<void> paySubscription(
      Subscription sub, double amount, Student student) async {
    final remaining = sub.remainingAmount;
    final paid = amount >= remaining ? remaining : amount;
    sub.paidAmount += paid;
    sub.status = sub.paidAmount >= sub.amount ? 'paid' : 'partial';
    sub.paidDate = _today();
    await (await database).update('subscriptions', sub.toMap(),
        where: 'id = ?', whereArgs: [sub.id]);
    student.balance += paid;
    await updateStudent(student);
    await addPayment(Payment(
      studentId: student.id!,
      studentName: student.name,
      amount: paid,
      date: _today(),
      note: 'اشتراك ${_monthName(sub.month)} ${sub.year}',
      type: 'subscription',
    ));
    await _checkAchievements(student);
  }

  // ====================== الدفعات ======================
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

  // ✅ تم إصلاح خطأ fold
  Future<double> getTotalCollectedThisMonth() async {
    final now = DateTime.now();
    final month = '/${now.month}/${now.year}';
    final all = await getAllPayments();
    double total = 0;
    for (final p in all.where((p) => p.date.endsWith(month))) {
      total += p.amount;
    }
    return total;
  }

  // ====================== الحضور ======================
  Future<void> addAttendance(AttendanceRecord a) async =>
      (await database).insert('attendance', a.toMap());

  Future<List<AttendanceRecord>> getStudentAttendance(int studentId) async {
    final res = await (await database).query('attendance',
        where: 'studentId = ?', whereArgs: [studentId], orderBy: 'id DESC');
    return res.map((e) => AttendanceRecord.fromMap(e)).toList();
  }

  Future<double> getAttendancePercentage(int studentId) async {
    final records = await getStudentAttendance(studentId);
    if (records.isEmpty) return 0;
    return records.where((x) => x.present).length / records.length * 100;
  }

  Future<List<Student>> getStudentsWithDebt() async {
    final res = await (await database).query('students',
        where: 'balance < 0 AND archived = 0', orderBy: 'balance ASC');
    return res.map((e) => Student.fromMap(e)).toList();
  }

  // ====================== QR الحضور ======================
  Future<Map<String, dynamic>> markAttendanceByQR(
      int studentId, String groupName, double price) async {
    final student = await getStudentById(studentId);
    if (student == null) {
      return {'success': false, 'message': 'الطالب غير موجود'};
    }
    final today = _today();
    final db = await database;
    final existing = await db.query('attendance',
        where: 'studentId = ? AND date = ? AND groupName = ?',
        whereArgs: [studentId, today, groupName]);
    if (existing.isNotEmpty) {
      return {
        'success': false,
        'message': 'تم تسجيل ${student.name} بالفعل اليوم',
        'student': student
      };
    }
    await addAttendance(AttendanceRecord(
      studentId: student.id!,
      studentName: student.name,
      groupName: groupName,
      date: today,
      present: true,
    ));
    student.balance -= price;
    student.xp += 10;
    await updateStudent(student);
    await _checkAchievements(student);
    return {
      'success': true,
      'message': 'أهلاً ${student.name}! ✅',
      'student': student
    };
  }

  // ====================== الإنجازات ======================
  Future<List<String>> getStudentAchievements(int studentId) async {
    final res = await (await database).query('student_achievements',
        where: 'studentId = ?', whereArgs: [studentId]);
    return res.map((e) => e['achievementId'] as String).toList();
  }

  Future<bool> hasAchievement(int studentId, String achievementId) async {
    final res = await (await database).query('student_achievements',
        where: 'studentId = ? AND achievementId = ?',
        whereArgs: [studentId, achievementId]);
    return res.isNotEmpty;
  }

  Future<void> _grantAchievement(int studentId, String achievementId) async {
    final exists = await hasAchievement(studentId, achievementId);
    if (!exists) {
      await (await database).insert('student_achievements', {
        'studentId': studentId,
        'achievementId': achievementId,
        'date': _today(),
      });

      final achievement = Achievements.getById(achievementId);
      if (achievement != null) {
        await addNotification(AppNotification(
          title: '🎉 إنجاز جديد!',
          body: 'حصلت على إنجاز: ${achievement.title}',
          type: 'achievement',
          date: _today(),
          studentId: studentId,
        ));
      }
    }
  }

  Future<void> _checkAchievements(Student s) async {
    if (s.xp >= 50) await _grantAchievement(s.id!, 'xp_50');
    if (s.xp >= 200) await _grantAchievement(s.id!, 'xp_200');
    if (s.xp >= 500) await _grantAchievement(s.id!, 'xp_500');
    if (s.balance >= 0) await _grantAchievement(s.id!, 'regular_payment');

    final records = await getStudentAttendance(s.id!);
    if (records.length >= 10) {
      bool consecutive = true;
      for (int i = 0; i < 10; i++) {
        if (!records[i].present) {
          consecutive = false;
          break;
        }
      }
      if (consecutive) await _grantAchievement(s.id!, 'attend_10');
    }

    final subs = await getSubscriptions(studentId: s.id!);
    final paidSubs = subs.where((x) => x.status == 'paid').length;
    if (paidSubs >= 3) await _grantAchievement(s.id!, 'sub_paid_3');
  }

  // ====================== التقييم الأكاديمي ======================
  Future<int> addAcademicRecord(AcademicRecord record) async {
    return await (await database).insert('grades', record.toMap());
  }

  Future<List<AcademicGrade>> getStudentGrades(int studentId) async {
    final db = await database;
    final res = await db.query(
      'grades',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'date DESC',
    );
    return res.map((e) => AcademicGrade.fromMap(e)).toList();
  }

  Future<Map<String, dynamic>> getStudentAcademicSummary(int studentId) async {
    final grades = await getStudentGrades(studentId);
    if (grades.isEmpty) {
      return {
        'average': 0.0,
        'excellent': 0,
        'good': 0,
        'acceptable': 0,
        'weak': 0,
      };
    }

    int excellent = grades.where((g) => g.grade == 'excellent').length;
    int good = grades.where((g) => g.grade == 'good').length;
    int acceptable = grades.where((g) => g.grade == 'acceptable').length;
    int weak = grades.where((g) => g.grade == 'weak').length;

    double average = (excellent * 100 + good * 75 + acceptable * 50 + weak * 25) /
        grades.length;

    return {
      'average': average,
      'excellent': excellent,
      'good': good,
      'acceptable': acceptable,
      'weak': weak,
    };
  }

  Future<List<Map<String, dynamic>>> getWeakStudents() async {
    final students = await getStudents();
    List<Map<String, dynamic>> weak = [];

    for (final s in students) {
      final grades = await getStudentGrades(s.id!);
      final weakCount = grades.where((g) => g.grade == 'weak').length;
      final pct = await getAttendancePercentage(s.id!);

      if (weakCount >= 2 || pct < 50) {
        weak.add({
          'student': s,
          'weakCount': weakCount,
          'attendance': pct,
        });
      }
    }

    weak.sort((a, b) => (b['weakCount'] as int).compareTo(a['weakCount'] as int));
    return weak;
  }

  // ====================== الإشعارات ======================
  Future<int> addNotification(AppNotification notification) async {
    return await (await database).insert('notifications', notification.toMap());
  }

  Future<List<AppNotification>> getNotifications({int? studentId}) async {
    final db = await database;
    List<Map<String, dynamic>> res;

    if (studentId != null) {
      res = await db.query(
        'notifications',
        where: 'studentId = ?',
        whereArgs: [studentId],
        orderBy: 'id DESC',
      );
    } else {
      res = await db.query('notifications', orderBy: 'id DESC', limit: 50);
    }

    return res.map((e) => AppNotification.fromMap(e)).toList();
  }

  Future<int> getUnreadCount({int? studentId}) async {
    final db = await database;
    final res = await db.query(
      'notifications',
      where: studentId != null ? 'isRead = 0 AND studentId = ?' : 'isRead = 0',
      whereArgs: studentId != null ? [studentId] : null,
    );
    return res.length;
  }

  Future<void> markAllRead({int? studentId}) async {
    final db = await database;
    if (studentId != null) {
      await db.update(
        'notifications',
        {'isRead': 1},
        where: 'studentId = ?',
        whereArgs: [studentId],
      );
    } else {
      await db.update('notifications', {'isRead': 1});
    }
  }

  // ====================== العملات ======================
  Future<int> addCoinTransaction(CoinTransaction transaction) async {
    return await (await database)
        .insert('coin_transactions', transaction.toMap());
  }

  // ✅ تم إصلاح خطأ fold
  Future<List<Map<String, dynamic>>> getCoinsLeaderboard() async {
    final students = await getStudents();
    List<Map<String, dynamic>> leaderboard = [];

    for (final s in students) {
      final res = await (await database).query(
        'coin_transactions',
        where: 'studentId = ?',
        whereArgs: [s.id],
      );
      int total = 0;
      for (final t in res) {
        total += (t['amount'] as int);
      }
      leaderboard.add({
        'id': s.id,
        'name': s.name,
        'totalCoins': total,
      });
    }

    leaderboard.sort(
        (a, b) => (b['totalCoins'] as int).compareTo(a['totalCoins'] as int));
    return leaderboard;
  }

  Future<int> getStudentCoins(int studentId) async {
    final res = await (await database).query(
      'coin_transactions',
      where: 'studentId = ?',
      whereArgs: [studentId],
    );
    int total = 0;
    for (final t in res) {
      total += (t['amount'] as int);
    }
    return total;
  }

  // ====================== التقارير الذكية ======================
  Future<Map<String, dynamic>> getSmartReport() async {
    final students = await getStudents();
    final payments = await getAllPayments();
    final now = DateTime.now();
    final month = '/${now.month}/${now.year}';
    final monthlyPayments = payments.where((p) => p.date.endsWith(month)).toList();

    List<Map<String, dynamic>> stats = [];
    for (final s in students) {
      final pct = await getAttendancePercentage(s.id!);
      stats.add({'student': s, 'percentage': pct});
    }
    stats.sort((a, b) => (b['percentage'] as double).compareTo(a['percentage'] as double));

    final debtStudents = students.where((s) => s.balance < 0).toList();

    List<Map<String, dynamic>> riskStudents = [];
    for (final s in students) {
      final pct = await getAttendancePercentage(s.id!);
      final risk = s.riskLevel(pct);
      if (risk != 'ملتزم') riskStudents.add({'student': s, 'risk': risk, 'attendance': pct});
    }

    final subs = await getSubscriptions(month: now.month, year: now.year);
    double expectedIncome = 0;
    for (final x in subs) {
      expectedIncome += x.amount;
    }
    double actualIncome = 0;
    for (final p in monthlyPayments) {
      actualIncome += p.amount;
    }

    double totalDebt = 0;
    for (final st in debtStudents) {
      totalDebt += st.balance.abs();
    }

    return {
      'bestAttendance': stats.take(3).toList(),
      'mostAbsent': stats.reversed.take(3).toList(),
      'monthlyIncome': actualIncome,
      'expectedIncome': expectedIncome,
      'collectionRate': expectedIncome > 0 ? (actualIncome / expectedIncome * 100) : 0.0,
      'debtStudents': debtStudents,
      'totalDebt': totalDebt,
      'weekStar': students.isNotEmpty ? students.first : null,
      'totalStudents': students.length,
      'monthlyPaymentsCount': monthlyPayments.length,
      'riskStudents': riskStudents,
      'allStudentsStats': stats,
    };
  }
}