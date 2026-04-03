import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen();
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    await DatabaseHelper.instance.generateSmartNotifications();
    final data = await DatabaseHelper.instance.getNotifications();
    if (!mounted) return;
    setState(() { _notifs = data; _loading = false; });
  }

  Color _tc(String t) { switch (t) { case 'debt': return AppTheme.danger; case 'absence': return AppTheme.warning; default: return AppTheme.primary; } }

  @override
  Widget build(BuildContext context) {
    final unread = _notifs.where((n) => !n.isRead).length;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [ const Text('الإشعارات'), if (unread > 0) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(20)), child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))]]),
        actions: [if (unread > 0) TextButton(onPressed: () async { await DatabaseHelper.instance.markAllRead(); _load(); }, child: const Text('قراءة الكل', style: TextStyle(color: Colors.white)))],
      ),
      body: _loading ? const LoadingWidget() : _notifs.isEmpty
          ? const EmptyState(icon: Icons.notifications_none, title: 'لا توجد إشعارات', subtitle: 'ستظهر هنا التنبيهات تلقائياً')
          : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _notifs.length, itemBuilder: (ctx, i) {
              final n = _notifs[i]; final isDark = Theme.of(context).brightness == Brightness.dark; final c = _tc(n.type);
              return Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: n.isRead ? (isDark ? AppTheme.bgCardDark : AppTheme.bgCard) : c.withOpacity(0.06), borderRadius: BorderRadius.circular(13), border: Border.all(color: n.isRead ? const Color(0xFFE2E8F0) : c.withOpacity(0.28))), child: Row(children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(11)), child: Center(child: Text(n.typeIcon, style: const TextStyle(fontSize: 16)))),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))), if (!n.isRead) Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle))]),
                  Text(n.body, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(n.date, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                ])),
              ]));
            }),
      floatingActionButton: FloatingActionButton.small(backgroundColor: AppTheme.primary, child: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
    );
  }
}
