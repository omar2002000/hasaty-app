// lib/models/whatsapp.dart

class WhatsAppTemplate {
  final String id;
  final String title;
  final String emoji;
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