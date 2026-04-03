import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class SessionScreen extends StatefulWidget {
  final Group group;
  const SessionScreen({required this.group});
  @override
  _SessionScreenState createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  List<Student> _students = [];
  Map<int, bool> _attendance = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final all = await DatabaseHelper.instance.getStudents();
    final grp = all.where((s) => s.groupName == widget.group.name).toList();
    if (!mounted) return;
    setState(() {
      _students = grp;
      for (final s in grp) _attendance[s.id!] = true;
      _loading = false;
    });
  }

  Future<void> _finish() async {
    final now = DateTime.now(); final date = '${now.day}/${now.month}/${now.year}';
    final absent = <Student>[];
    for (final s in _students) {
      final present = _attendance[s.id] == true;
      if (present) { s.balance -= widget.group.monthlyPrice; s.xp += 10; await DatabaseHelper.instance.updateStudent(s); }
      else absent.add(s);
      await DatabaseHelper.instance.addAttendance(AttendanceRecord(studentId: s.id!, studentName: s.name, groupName: widget.group.name, date: date, present: present));
    }
    if (!mounted) return;
    Navigator.pop(context);
    if (absent.isNotEmpty) _absenceDialog(absent);
    else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم إنهاء الحصة بنجاح'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
  }

  void _absenceDialog(List<Student> absent) => showDialog(context: context, builder: (ctx) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Row(children: [const Icon(Icons.notifications_active, color: AppTheme.warning), const SizedBox(width: 8), const Text('الطلاب الغائبون')]),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('غاب ${absent.length} طالب — هل تريد إرسال تذكير واتساب؟'),
      const SizedBox(height: 10),
      ...absent.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [const Icon(Icons.person_off, size: 15, color: AppTheme.danger), const SizedBox(width: 6), Text(s.name)]))),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تجاهل')),
      ElevatedButton.icon(
        icon: const Icon(Icons.send, color: Colors.white, size: 14),
        label: const Text('إرسال للكل', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
        onPressed: () { Navigator.pop(ctx); _sendAbsence(absent); },
      ),
    ],
  ));

  Future<void> _sendAbsence(List<Student> absent) async {
    for (final s in absent) {
      final p = s.phone.startsWith('0') ? s.phone.substring(1) : s.phone;
      final msg = Uri.encodeComponent(WhatsAppTemplates.absence(s.name, widget.group.name));
      final url = Uri.parse('https://wa.me/20$p?text=$msg');
      if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); await Future.delayed(const Duration(seconds: 2)); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final present = _attendance.values.where((v) => v).length;
    final absent  = _attendance.values.where((v) => !v).length;
    return Scaffold(
      appBar: AppBar(title: Text('حصة: ${widget.group.name}'), backgroundColor: AppTheme.primary),
      body: _loading ? const LoadingWidget() : Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: AppTheme.primary.withOpacity(0.05),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _sum('الكل',    _students.length.toString(), AppTheme.primary),
            _sum('حاضر',   present.toString(),           AppTheme.success),
            _sum('غائب',   absent.toString(),            AppTheme.danger),
            _sum('سعر الحصة', '${widget.group.monthlyPrice.toStringAsFixed(0)} ج', AppTheme.warning),
          ]),
        ),
        Expanded(child: _students.isEmpty
            ? const EmptyState(icon: Icons.people_outline, title: 'لا يوجد طلاب', subtitle: 'أضف طلاباً لهذه المجموعة')
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _students.length,
                itemBuilder: (ctx, i) {
                  final s = _students[i]; final isP = _attendance[s.id]!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('رصيده: ${s.balance.toStringAsFixed(0)} ج.م | XP: ${s.xp}'),
                      value: isP, activeColor: AppTheme.success,
                      onChanged: (v) => setState(() => _attendance[s.id!] = v),
                      secondary: CircleAvatar(
                        backgroundColor: (isP ? AppTheme.success : AppTheme.danger).withOpacity(0.15),
                        child: Icon(isP ? Icons.check : Icons.close, color: isP ? AppTheme.success : AppTheme.danger, size: 18),
                      ),
                    ),
                  );
                },
              )),
      ]),
      bottomNavigationBar: SafeArea(child: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.done_all, color: Colors.white),
          label: Text('إنهاء الحصة وخصم الرصيد ($present حاضر)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: _students.isEmpty ? null : _finish,
        ),
      )),
    );
  }

  Widget _sum(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    Text(label,  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
  ]);
}
