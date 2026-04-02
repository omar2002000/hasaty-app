// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../database_helper.dart';
import '../models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // التعامل مع الضغط على الإشعار
    print('Notification tapped: ${response.payload}');
  }

  // إرسال إشعار فوري
  Future<void> sendNotification({
    required String title,
    required String body,
    String? payload,
    int? studentId,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'hasaty_channel',
      'حصتي',
      channelDescription: 'إشعارات تطبيق حصتي',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    // حفظ الإشعار في قاعدة البيانات
    if (studentId != null) {
      await DatabaseHelper.instance.addNotification(AppNotification(
        title: title,
        body: body,
        type: 'push',
        date: _today(),
        studentId: studentId,
      ));
    }
  }

  // جدولة إشعار
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    int? studentId,
  }) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'hasaty_channel',
      'حصتي',
      channelDescription: 'إشعارات مجدولة',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosPlatformChannelSpecifics = DarwinNotificationDetails();

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      scheduledDate.millisecond,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // إشعار تذكير بالحصة
  Future<void> scheduleClassReminder(Group group, DateTime classTime) async {
    final reminderTime = classTime.subtract(const Duration(minutes: 30));
    await scheduleNotification(
      title: '🔔 تذكير: حصة ${group.name}',
      body: 'تبدأ الحصة بعد 30 دقيقة',
      scheduledDate: reminderTime,
      payload: 'group_${group.id}',
    );
  }

  // إشعار تذكير بالاشتراك
  Future<void> scheduleSubscriptionReminder(Student student) async {
    final now = DateTime.now();
    final reminderDate = DateTime(now.year, now.month + 1, 5); // اليوم الخامس من الشهر القادم
    
    await scheduleNotification(
      title: '💰 تذكير بالاشتراك',
      body: '${student.name}، الاشتراك الشهري قارب على الانتهاء',
      scheduledDate: reminderDate,
      payload: 'subscription_${student.id}',
      studentId: student.id,
    );
  }

  // إشعار إنجاز جديد
  Future<void> notifyAchievement(Student student, String achievementName) async {
    await sendNotification(
      title: '🎉 إنجاز جديد!',
      body: 'مبروك ${student.name}! حصلت على إنجاز: $achievementName',
      payload: 'achievement_${student.id}',
      studentId: student.id,
    );
  }

  // إشعار تحذير (ديون/غياب)
  Future<void> sendWarningNotification(Student student, String warningType) async {
    String title, body;
    switch (warningType) {
      case 'debt':
        title = '⚠️ تنبيه مالي';
        body = 'الرصيد المستحق عليك: ${student.balance.abs().toStringAsFixed(0)} ج.م';
        break;
      case 'absence':
        title = '📵 تنبيه غياب';
        body = 'نسبة غيابك: ${await _getAbsencePercentage(student.id!)}%';
        break;
      default:
        title = 'تنبيه';
        body = 'يرجى متابعة أداء الطالب';
    }
    
    await sendNotification(
      title: title,
      body: body,
      payload: 'warning_${student.id}',
      studentId: student.id,
    );
  }

  // جدولة إشعارات أسبوعية
  Future<void> scheduleWeeklyReport() async {
    final now = DateTime.now();
    final nextSunday = now.add(Duration(days: 7 - now.weekday));
    final reportTime = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 18, 0);
    
    await scheduleNotification(
      title: '📊 التقرير الأسبوعي',
      body: 'اطلع على أداء الطلاب هذا الأسبوع',
      scheduledDate: reportTime,
      payload: 'weekly_report',
    );
  }

  String _today() {
    final n = DateTime.now();
    return '${n.day}/${n.month}/${n.year}';
  }

  Future<double> _getAbsencePercentage(int studentId) async {
    final db = DatabaseHelper.instance;
    final pct = await db.getAttendancePercentage(studentId);
    return 100 - pct;
  }

  // إلغاء جميع الإشعارات المجدولة
  Future<void> cancelAllScheduled() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}