// lib/screens/interactive_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database_helper.dart';
import '../models.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';

class InteractiveScheduleScreen extends StatefulWidget {
  const InteractiveScheduleScreen({super.key});
  
  @override
  State<InteractiveScheduleScreen> createState() => _InteractiveScheduleScreenState();
}

class _InteractiveScheduleScreenState extends State<InteractiveScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<Group> _groups = [];
  Map<DateTime, List<ScheduleEvent>> _events = {};
  bool _loading = true;
  
  final NotificationService _notificationService = NotificationService();
  final ReminderService _reminderService = ReminderService();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final groups = await DatabaseHelper.instance.getGroups();
    setState(() {
      _groups = groups;
      _loading = false;
    });
    _generateSchedule();
  }
  
  void _generateSchedule() {
    _events.clear();
    
    for (final group in _groups) {
      final daysList = group.days.split(',').where((d) => d.isNotEmpty).toList();
      final time = _parseTime(group.time);
      
      for (final day in daysList) {
        final dayIndex = _getDayIndex(day);
        // توليد الأحداث للأشهر القادمة
        for (int i = 0; i < 12; i++) {
          final date = _getNextDate(DateTime.now().add(Duration(days: i * 30)), dayIndex);
          if (date.isAfter(DateTime.now().subtract(const Duration(days: 30)))) {
            _events.putIfAbsent(date, () => []).add(ScheduleEvent(
              group: group,
              time: time,
              type: 'class',
            ));
          }
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول الحصص'),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              _loadData();
              _generateSchedule();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 30)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  calendarFormat: _calendarFormat,
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  eventLoader: (day) => _events[day] ?? [],
                  calendarStyle: const CalendarStyle(
                    weekendTextStyle: TextStyle(color: Colors.red),
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _buildEventsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickScheduleDialog,
        backgroundColor: AppTheme.success,
        icon: const Icon(Icons.schedule),
        label: const Text('جدولة سريعة'),
      ),
    );
  }
  
  Widget _buildEventsList() {
    final events = _events[_selectedDay] ?? [];
    
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد حصص في هذا اليوم', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (ctx, i) {
        final event = events[i];
        return _eventCard(event);
      },
    );
  }
  
  Widget _eventCard(ScheduleEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.group.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(event.time),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${event.group.price.toStringAsFixed(0)} ج',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionButton(
                'تعديل',
                Icons.edit,
                AppTheme.primary,
                () => _showEditEventDialog(event),
              ),
              const SizedBox(width: 8),
              _actionButton(
                'تذكير',
                Icons.notifications,
                AppTheme.warning,
                () => _setReminder(event),
              ),
              const SizedBox(width: 8),
              _actionButton(
                'بدء الحصة',
                Icons.play_circle,
                AppTheme.success,
                () => _startSession(event.group),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 18),
                onPressed: () => _showEventMenu(event),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: color),
        label: Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  void _showAddEventDialog() {
    // إضافة حصة يدوية
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة حصة جديدة'),
        content: const Text('اختر المجموعة والتاريخ'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إضافة')),
        ],
      ),
    );
  }
  
  void _showQuickScheduleDialog() {
    // جدولة سريعة لحصص الأسبوع
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('جدولة سريعة'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('اختر أيام الحصص:'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: const [
                    FilterChip(label: Text('السبت'), selected: false, onSelected: null),
                    FilterChip(label: Text('الأحد'), selected: false, onSelected: null),
                    FilterChip(label: Text('الإثنين'), selected: false, onSelected: null),
                    FilterChip(label: Text('الثلاثاء'), selected: false, onSelected: null),
                    FilterChip(label: Text('الأربعاء'), selected: false, onSelected: null),
                    FilterChip(label: Text('الخميس'), selected: false, onSelected: null),
                  ],
                ),
                const SizedBox(height: 12),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'وقت الحصة',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('حفظ')),
          ],
        ),
      ),
    );
  }
  
  void _showEditEventDialog(ScheduleEvent event) {
    // تعديل الحصة
  }
  
  void _showEventMenu(ScheduleEvent event) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف الحصة'),
              onTap: () {
                Navigator.pop(ctx);
                _deleteEvent(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('تكرار أسبوعي'),
              onTap: () {
                Navigator.pop(ctx);
                _repeatWeekly(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('عرض الطلاب'),
              onTap: () {
                Navigator.pop(ctx);
                _showGroupStudents(event.group);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _deleteEvent(ScheduleEvent event) {
    setState(() {
      _events[_selectedDay]?.remove(event);
      if (_events[_selectedDay]?.isEmpty == true) {
        _events.remove(_selectedDay);
      }
    });
  }
  
  void _repeatWeekly(ScheduleEvent event) {
    // تكرار الحصة أسبوعياً
  }
  
  void _showGroupStudents(Group group) {
    // عرض طلاب المجموعة
  }
  
  Future<void> _setReminder(ScheduleEvent event) async {
    final date = _selectedDay;
    final time = event.time;
    final reminderTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).subtract(const Duration(minutes: 30));
    
    await _notificationService.scheduleNotification(
      title: '🔔 تذكير: حصة ${event.group.name}',
      body: 'تبدأ الحصة بعد 30 دقيقة',
      scheduledDate: reminderTime,
      payload: 'group_${event.group.id}',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تعيين تذكير للحصة'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }
  
  void _startSession(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SessionScreen(group: group)),
    );
  }
  
  // دوال مساعدة
  DateTime _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      if (parts.length > 1 && parts[1] == 'م') {
        hour += 12;
      }
      return DateTime(2000, 1, 1, hour, minute);
    } catch (_) {
      return DateTime(2000, 1, 1, 17, 0);
    }
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
  
  int _getDayIndex(String day) {
    switch (day) {
      case 'السبت': return 6;
      case 'الأحد': return 7;
      case 'الإثنين': return 1;
      case 'الثلاثاء': return 2;
      case 'الأربعاء': return 3;
      case 'الخميس': return 4;
      case 'الجمعة': return 5;
      default: return 1;
    }
  }
  
  DateTime _getNextDate(DateTime from, int targetWeekday) {
    int daysToAdd = (targetWeekday - from.weekday + 7) % 7;
    if (daysToAdd == 0) daysToAdd = 7;
    return from.add(Duration(days: daysToAdd));
  }
}

class ScheduleEvent {
  final Group group;
  final DateTime time;
  final String type;
  
  ScheduleEvent({
    required this.group,
    required this.time,
    required this.type,
  });
}