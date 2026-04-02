// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getNotifications();
    setState(() {
      _notifications = data;
      _loading = false;
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_amber;
      case 'achievement':
        return Icons.emoji_events;
      case 'payment':
        return Icons.payments;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'alert':
        return AppTheme.danger;
      case 'achievement':
        return AppTheme.warning;
      case 'payment':
        return AppTheme.success;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                await DatabaseHelper.instance.markAllRead();
                _load();
              },
              child: const Text('مسح الكل', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : _notifications.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_off,
                  title: 'لا توجد إشعارات',
                  subtitle: 'ستظهر الإشعارات هنا عند حدوث أحداث مهمة',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (ctx, i) {
                    final n = _notifications[i];
                    final color = _getColor(n.type);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: n.isRead
                            ? (isDark ? AppTheme.bgCardDark : AppTheme.bgCard)
                            : color.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: n.isRead
                              ? const Color(0xFFE2E8F0)
                              : color.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getIcon(n.type), color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  n.body,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.date,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}