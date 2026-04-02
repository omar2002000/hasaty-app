// lib/models/group.dart

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