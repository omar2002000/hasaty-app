import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'qr_scanner_screen.dart';
import 'session_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen();
  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Group> _groups = [];
  bool _loading = true;
  final _days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getGroups();
    if (!mounted) return;
    setState(() { _groups = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المجموعات')),
      body: _loading ? const LoadingWidget() : _groups.isEmpty
          ? EmptyState(icon: Icons.groups_outlined, title: 'لا توجد مجموعات بعد', subtitle: 'اضغط + لإضافة مجموعة جديدة', actionLabel: 'إضافة مجموعة', onAction: () => _showDialog(null))
          : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _groups.length, itemBuilder: (ctx, i) => _card(_groups[i])),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('مجموعة جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showDialog(null),
      ),
    );
  }

  Widget _card(Group g) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = g.days.isNotEmpty ? g.days.split(',').where((d) => d.isNotEmpty).toList() : <String>[];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.groups, color: AppTheme.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${g.monthlyPrice.toStringAsFixed(0)} ج.م / شهر', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == 'edit')    _showDialog(g);
              if (v == 'delete')  _delete(g);
              if (v == 'message') _groupMsg(g);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit',    child: Row(children: [Icon(Icons.edit,         size: 16, color: AppTheme.primary),  SizedBox(width: 8), Text('تعديل')])),
              const PopupMenuItem(value: 'message', child: Row(children: [Icon(Icons.campaign,      size: 16, color: AppTheme.success),  SizedBox(width: 8), Text('رسالة للكل')])),
              PopupMenuItem( value: 'delete',  child: Row(children: [const Icon(Icons.delete_outline, size: 16, color: AppTheme.danger), const SizedBox(width: 8), Text('حذف', style: const TextStyle(color: AppTheme.danger))])),
            ],
          ),
        ]),
        if (days.isNotEmpty || g.time.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            ...days.map((d) => StatusBadge(label: d, color: AppTheme.accent)),
            if (g.time.isNotEmpty) StatusBadge(label: '🕐 ${g.time}', color: AppTheme.primary),
          ]),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _btn('بدء الحصة', Icons.play_circle_fill, AppTheme.success, () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(group: g))))),
          const SizedBox(width: 8),
          Expanded(child: _btn('تحضير QR',  Icons.qr_code_scanner,   AppTheme.purple,  () => Navigator.push(context, MaterialPageRoute(builder: (_) => QrScannerScreen(group: g))))),
        ]),
      ]),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) => ElevatedButton.icon(
    icon: Icon(icon, size: 15, color: Colors.white), label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    style: ElevatedButton.styleFrom(backgroundColor: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 9), minimumSize: const Size(double.infinity, 38)),
    onPressed: onTap,
  );

  Future<void> _groupMsg(Group g) async {
    String message = '';
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('رسالة جماعية — ${g.name}'),
      content: TextField(decoration: const InputDecoration(labelText: 'اكتب الرسالة', hintText: 'مثال: موعد الحصة الجمعة 5 م'), maxLines: 3, onChanged: (v) => message = v),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إرسال'))],
    ));
    if (message.isEmpty) return;
    final students = await DatabaseHelper.instance.getStudents();
    for (final s in students.where((s) => s.groupName == g.name)) {
      final p = s.phone.startsWith('0') ? s.phone.substring(1) : s.phone;
      final url = Uri.parse('https://wa.me/20$p?text=${Uri.encodeComponent('أهلاً يا ${s.name},\n$message\nمعلمك: مستر نصر علي')}');
      if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); await Future.delayed(const Duration(seconds: 2)); }
    }
  }

  Future<void> _delete(Group g) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('حذف المجموعة'),
      content: Text('هل أنت متأكد من حذف "${g.name}"؟'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('حذف', style: TextStyle(color: Colors.white)))],
    ));
    if (ok == true) { await DatabaseHelper.instance.deleteGroup(g.id!); _load(); }
  }

  void _showDialog(Group? existing) {
    String name = existing?.name ?? ''; double price = existing?.monthlyPrice ?? 0; String time = existing?.time ?? '';
    Set<String> selDays = existing?.days.isNotEmpty == true ? Set.from(existing!.days.split(',').where((d) => d.isNotEmpty)) : {};
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [const Icon(Icons.groups, color: AppTheme.primary), const SizedBox(width: 8), Text(existing == null ? 'إضافة مجموعة' : 'تعديل المجموعة')]),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: TextEditingController(text: name), decoration: const InputDecoration(labelText: 'اسم المجموعة', prefixIcon: Icon(Icons.groups)), onChanged: (v) => name = v),
        const SizedBox(height: 10),
        TextField(controller: TextEditingController(text: price == 0 ? '' : price.toStringAsFixed(0)), decoration: const InputDecoration(labelText: 'الاشتراك الشهري', prefixIcon: Icon(Icons.payments), suffixText: 'ج.م'), keyboardType: TextInputType.number, onChanged: (v) => price = double.tryParse(v) ?? 0),
        const SizedBox(height: 10),
        TextField(controller: TextEditingController(text: time), decoration: const InputDecoration(labelText: 'وقت الحصة', prefixIcon: Icon(Icons.access_time), hintText: '05:00 م'), onChanged: (v) => time = v),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: Text('أيام الحصص:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: _days.map((d) => FilterChip(
          label: Text(d, style: const TextStyle(fontSize: 12)), selected: selDays.contains(d),
          selectedColor: AppTheme.primary.withOpacity(0.2), checkmarkColor: AppTheme.primary,
          onSelected: (v) => setS(() { if (v) selDays.add(d); else selDays.remove(d); }),
        )).toList()),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (name.isEmpty || price <= 0) return;
            final g = Group(id: existing?.id, name: name, monthlyPrice: price, days: selDays.join(','), time: time);
            if (existing == null) await DatabaseHelper.instance.addGroup(g);
            else await DatabaseHelper.instance.updateGroup(g);
            if (!mounted) return;
            Navigator.pop(ctx); _load();
          },
          child: Text(existing == null ? 'إضافة' : 'حفظ'),
        ),
      ],
    )));
  }
}
