import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'session_screen.dart';
import 'qr_scanner_screen.dart';

class GroupsScreen extends StatefulWidget {
  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Group> groups = [];
  bool _loading = true;

  final _daysOptions = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

  @override
  void initState() { super.initState(); _load(); }

  _load() async {
    final data = await DatabaseHelper.instance.getGroups();
    setState(() { groups = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('المجموعات')),
      body: _loading ? LoadingWidget() : groups.isEmpty
        ? EmptyState(icon: Icons.groups_outlined, title: 'لا توجد مجموعات بعد', subtitle: 'اضغط + لإضافة مجموعة جديدة', actionLabel: 'إضافة مجموعة', onAction: _showAddDialog)
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (ctx, i) => _groupCard(groups[i]),
          ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('مجموعة جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAddDialog,
      ),
    );
  }

  Widget _groupCard(Group g) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysList = g.days.isNotEmpty ? g.days.split(',').where((d) => d.isNotEmpty).toList() : <String>[];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Color(0xFF334155) : Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.groups, color: AppTheme.primary, size: 22)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${g.monthlyPrice.toStringAsFixed(0)} ج.م / شهر', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ])),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'edit') _showEditDialog(g);
              if (val == 'delete') _confirmDelete(g);
              if (val == 'message') _sendGroupMessage(g);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16, color: AppTheme.primary), SizedBox(width: 8), Text('تعديل')])),
              PopupMenuItem(value: 'message', child: Row(children: [Icon(Icons.campaign, size: 16, color: AppTheme.success), SizedBox(width: 8), Text('رسالة للكل')])),
              PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppTheme.danger), SizedBox(width: 8), Text('حذف', style: TextStyle(color: AppTheme.danger))])),
            ],
          ),
        ]),

        // الأيام والمواعيد
        if (daysList.isNotEmpty || g.time.isNotEmpty) ...[
          SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 4, children: [
            ...daysList.map((d) => StatusBadge(label: d, color: AppTheme.accent)),
            if (g.time.isNotEmpty) StatusBadge(label: '🕐 ${g.time}', color: AppTheme.primary),
          ]),
        ],

        SizedBox(height: 12),
        Row(children: [
          Expanded(child: _btn('بدء الحصة', Icons.play_circle_fill, AppTheme.success, () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(group: g))))),
          SizedBox(width: 8),
          Expanded(child: _btn('تحضير QR', Icons.qr_code_scanner, AppTheme.purple, () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => QrScannerScreen(group: g))))),
        ]),
      ]),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) => ElevatedButton.icon(
    icon: Icon(icon, size: 16, color: Colors.white),
    label: Text(label, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    style: ElevatedButton.styleFrom(backgroundColor: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.symmetric(vertical: 10)),
    onPressed: onTap,
  );

  _sendGroupMessage(Group g) async {
    String message = '';
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('رسالة جماعية — ${g.name}'),
      content: TextField(
        decoration: InputDecoration(labelText: 'اكتب الرسالة', hintText: 'مثال: موعد الحصة الجمعة 5 م'),
        maxLines: 3, onChanged: (v) => message = v,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text('إرسال')),
      ],
    ));
    if (message.isEmpty) return;
    final students = await DatabaseHelper.instance.getStudents();
    final gs = students.where((s) => s.groupName == g.name).toList();
    for (var s in gs) {
      final p = s.phone.startsWith('0') ? s.phone.substring(1) : s.phone;
      final url = "https://wa.me/20$p?text=${Uri.encodeComponent('أهلاً يا ${s.name},\n$message\nمعلمك: مستر نصر علي')}";
      if (await canLaunchUrl(Uri.parse(url))) { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); await Future.delayed(Duration(seconds: 2)); }
    }
  }

  _confirmDelete(Group g) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('حذف المجموعة'),
      content: Text('هل أنت متأكد من حذف "${g.name}"؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: Text('حذف', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (ok == true) { await DatabaseHelper.instance.deleteGroup(g.id!); _load(); }
  }

  _showAddDialog() => _showGroupDialog(null);
  _showEditDialog(Group g) => _showGroupDialog(g);

  _showGroupDialog(Group? existing) {
    String name = existing?.name ?? '';
    double price = existing?.monthlyPrice ?? 0;
    String time = existing?.time ?? '';
    Set<String> selectedDays = existing?.days.isNotEmpty == true ? Set.from(existing!.days.split(',').where((d) => d.isNotEmpty)) : {};

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(Icons.groups, color: AppTheme.primary), SizedBox(width: 8), Text(existing == null ? 'إضافة مجموعة' : 'تعديل المجموعة')]),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: TextEditingController(text: name), decoration: InputDecoration(labelText: 'اسم المجموعة', prefixIcon: Icon(Icons.groups)), onChanged: (v) => name = v),
          SizedBox(height: 12),
          TextField(controller: TextEditingController(text: price == 0 ? '' : price.toStringAsFixed(0)), decoration: InputDecoration(labelText: 'الاشتراك الشهري', prefixIcon: Icon(Icons.payments), suffixText: 'ج.م'), keyboardType: TextInputType.number, onChanged: (v) => price = double.tryParse(v) ?? 0),
          SizedBox(height: 12),
          TextField(controller: TextEditingController(text: time), decoration: InputDecoration(labelText: 'وقت الحصة', prefixIcon: Icon(Icons.access_time), hintText: '05:00 م'), onChanged: (v) => time = v),
          SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: Text('أيام الحصص:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: _daysOptions.map((d) => FilterChip(
            label: Text(d, style: TextStyle(fontSize: 12)),
            selected: selectedDays.contains(d),
            selectedColor: AppTheme.primary.withOpacity(0.2),
            checkmarkColor: AppTheme.primary,
            onSelected: (v) => setS(() { if (v) selectedDays.add(d); else selectedDays.remove(d); }),
          )).toList()),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (name.isEmpty || price <= 0) return;
              final g = Group(id: existing?.id, name: name, monthlyPrice: price, days: selectedDays.join(','), time: time);
              if (existing == null) await DatabaseHelper.instance.addGroup(g);
              else await DatabaseHelper.instance.updateGroup(g);
              Navigator.pop(ctx);
              _load();
            },
            child: Text(existing == null ? 'إضافة' : 'حفظ'),
          ),
        ],
      ),
    ));
  }
}
