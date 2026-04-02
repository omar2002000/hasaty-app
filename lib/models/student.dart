// lib/models/student.dart

class Student {
  int? id;
  String name;
  String phone;
  String groupName;
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