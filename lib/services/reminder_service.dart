// lib/services/reminder_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class ReminderService {
  Future<void> setupAllReminders() async {
    await _scheduleDailyReminder();
  }

  Future<void> _scheduleDailyReminder() async {
    // ✅ استخدام الطريقة الصحيحة للإشعارات اليومية
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'تذكيرات حصتي',
      channelDescription: 'تذكيرات يومية للحصص',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // حساب الوقت المستهدف (8 صباحاً)
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 8, 0);
    final finalTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;
    
    final delay = finalTime.difference(now);
    
    // جدولة الإشعار
    await Future.delayed(delay);
    
    await flutterLocalNotificationsPlugin.show(
      1,
      'تذكير حصتي',
      'حان وقت الحصة! لا تنسى تسجيل الحضور 📚',
      details,
    );
    
    // إعادة جدولة الإشعار لليوم التالي
    Future.delayed(const Duration(days: 1), () => _scheduleDailyReminder());
  }
}