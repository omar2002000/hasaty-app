// lib/models/special_badges.dart
import 'package:flutter/material.dart';

class SpecialBadge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final String condition;
  final int xpReward;
  final bool isSecret;
  final bool isLimited;
  final int? maxCount;
  
  const SpecialBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.condition,
    this.xpReward = 0,
    this.isSecret = false,
    this.isLimited = false,
    this.maxCount,
  });
}

class SpecialBadges {
  static const List<SpecialBadge> all = [
    SpecialBadge(
      id: 'perfect_month',
      title: 'شهر كامل',
      description: 'حضور 100% طوال الشهر',
      emoji: '🌟',
      color: Colors.amber,
      condition: 'حضور كل الحصص في شهر ميلادي كامل',
      xpReward: 100,
    ),
    SpecialBadge(
      id: 'top_3_months',
      title: 'منصة التتويج',
      description: 'التواجد في المراكز الثلاثة الأولى لمدة 3 أشهر متتالية',
      emoji: '👑',
      color: Colors.purple,
      condition: '3 أشهر متتالية في المراكز الثلاثة الأولى',
      xpReward: 200,
    ),
    SpecialBadge(
      id: 'teacher_helper',
      title: 'مساعد المعلم',
      description: 'مساعدة المعلم في تنظيم الحصة',
      emoji: '🤝',
      color: Colors.blue,
      condition: 'يتم منحها يدوياً من المعلم',
      xpReward: 50,
      isSecret: false,
    ),
    SpecialBadge(
      id: 'early_bird',
      title: 'الطائر المبكر',
      description: 'أول طالب يحضر للحصة',
      emoji: '🐦',
      color: Colors.green,
      condition: 'أول 3 طلاب يحضرون الحصة',
      xpReward: 10,
    ),
    SpecialBadge(
      id: 'quiz_master',
      title: 'سيد الاختبارات',
      description: 'الحصول على 10 تقييمات ممتازة متتالية',
      emoji: '📚',
      color: Colors.teal,
      condition: '10 تقييمات ممتازة متتالية',
      xpReward: 75,
    ),
    SpecialBadge(
      id: 'social_leader',
      title: 'قائد اجتماعي',
      description: 'مساعدة زملائه في الدراسة',
      emoji: '🤝',
      color: Colors.orange,
      condition: 'يتم منحها من المعلم',
      xpReward: 60,
    ),
    SpecialBadge(
      id: 'perfect_payment',
      title: 'ملتزم مادياً',
      description: 'سداد الاشتراكات في موعدها لمدة 6 أشهر',
      emoji: '💰',
      color: Colors.green,
      condition: '6 أشهر متتالية سداد كامل',
      xpReward: 150,
    ),
    SpecialBadge(
      id: 'secret_achiever',
      title: '???',
      description: 'إنجاز سري',
      emoji: '❓',
      color: Colors.grey,
      condition: 'يتم اكتشافه تلقائياً',
      xpReward: 500,
      isSecret: true,
    ),
    SpecialBadge(
      id: 'legendary_1000',
      title: 'أسطوري',
      description: 'الوصول إلى 1000 نقطة XP',
      emoji: '🏆',
      color: Colors.red,
      condition: 'تجميع 1000 نقطة XP',
      xpReward: 200,
    ),
    SpecialBadge(
      id: 'perfect_attendance_20',
      title: 'حضور مثالي',
      description: '20 حصة حضور متتالية',
      emoji: '⭐',
      color: Colors.amber,
      condition: '20 حصة حضور بدون غياب',
      xpReward: 100,
    ),
  ];
  
  static SpecialBadge? getById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
  
  static List<SpecialBadge> getNonSecret() {
    return all.where((b) => !b.isSecret).toList();
  }
  
  static List<SpecialBadge> getLimited() {
    return all.where((b) => b.isLimited).toList();
  }
  
  static List<SpecialBadge> getByXpReward(int minXp) {
    return all.where((b) => b.xpReward >= minXp).toList();
  }
}