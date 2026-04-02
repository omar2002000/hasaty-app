// lib/models/achievements.dart

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