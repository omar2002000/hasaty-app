// lib/services/whatsapp_service.dart

import 'package:url_launcher/url_launcher.dart';
import '../models.dart';

class WhatsAppService {
  static Future<void> send(String phone, String message) async {
    String formattedPhone = phone.startsWith('0') ? phone.substring(1) : phone;
    final url = "https://wa.me/20$formattedPhone?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  static String gradeMessage(Student student, String type, String grade) {
    final gradeLabels = {
      'excellent': 'ممتاز',
      'good': 'جيد',
      'acceptable': 'مقبول',
      'weak': 'ضعيف',
    };
    
    final typeLabels = {
      'recitation': 'تسميع',
      'homework': 'واجب',
      'exam': 'اختبار',
    };
    
    return 'أهلاً ولي أمر ${student.name}،\nتقييم الطالب في ${typeLabels[type] ?? type}: ${gradeLabels[grade] ?? grade}\nمعلمك: مستر نصر علي';
  }

  static String warningMessage(Student student, double attendance) {
    return '⚠️ تنبيه مهم\nأهلاً ولي أمر ${student.name}،\nنسبة حضور الطالب: ${attendance.toStringAsFixed(0)}%\nنرجو متابعة الحضور بانتظام.\nمعلمك: مستر نصر علي';
  }
}