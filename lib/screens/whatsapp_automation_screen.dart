// ===================== whatsapp_automation_screen.dart =====================
// احفظ هذا الملف في lib/screens/whatsapp_automation_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class WhatsAppAutomationScreen extends StatefulWidget {
  const WhatsAppAutomationScreen();
  @override
  _WhatsAppAutomationScreenState createState() => _WhatsAppAutomationScreenState();
}

class _WhatsAppAutomationScreenState extends State<WhatsAppAutomationScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Student> _debt = [], _absent = [];
  bool _loading = true;
  final _months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final debts   = await DatabaseHelper.instance.getStudentsWithDebt();
    final students = await DatabaseHelper.instance.getStudents();
    final absent = <Student>[];
    for (final s in students) { final p = await DatabaseHelper.instance.getAttendancePercentage(s.id!); if (p < 60 && p > 0) absent.add(s); }
    if (!mounted) return;
    setState(() { _debt = debts; _absent = absent; _loading = false; });
  }

  Future<void> _send(Student s, String msg) async {
    final p = s.phone.startsWith('0') ? s.phone.substring(1) : s.phone;
    final url = Uri.parse('https://wa.me/20$p?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مركز واتساب التلقائي'), bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white, tabs: [Tab(text: 'مالي (${_debt.length})'), Tab(text: 'غياب (${_absent.length})'), const Tab(text: 'تقارير')])),
    body: _loading ? const LoadingWidget() : TabBarView(controller: _tab, children: [_debtTab(), _absTab(), _reportsTab()]),
  );

  Widget _debtTab() => Column(children: [
    _bulkCard('إرسال تذكير مالي للجميع (${_debt.length} طالب)', AppTheme.warning, () => _sendBulk(_debt, 'debt')),
    Expanded(child: _debt.isEmpty ? const EmptyState(icon: Icons.check_circle_outline, title: 'لا يوجد مديونون', subtitle: 'جميع الطلاب ملتزمون مالياً 🎉')
        : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 14), itemCount: _debt.length, itemBuilder: (ctx, i) => _tile(_debt[i], '${_debt[i].balance.abs().toStringAsFixed(0)} ج دين', AppTheme.danger, () => _send(_debt[i], WhatsAppTemplates.debt(_debt[i].name, _debt[i].balance.abs().toStringAsFixed(0)))))),
  ]);

  Widget _absTab() => Column(children: [
    _bulkCard('إرسال تذكير غياب للجميع (${_absent.length} طالب)', AppTheme.danger, () => _sendBulk(_absent, 'absence')),
    Expanded(child: _absent.isEmpty ? const EmptyState(icon: Icons.how_to_reg, title: 'جميع الطلاب ملتزمون', subtitle: 'لا يوجد طلاب بنسبة غياب عالية 🎉')
        : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 14), itemCount: _absent.length, itemBuilder: (ctx, i) => _tile(_absent[i], 'غياب متكرر', AppTheme.warning, () => _send(_absent[i], WhatsAppTemplates.absence(_absent[i].name, _absent[i].groupName))))),
  ]);

  Widget _reportsTab() {
    final now = DateTime.now();
    return SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(children: [
      _tplCard('📊 تقرير شهري للكل', 'ملخص أداء كل الطلاب', AppTheme.primary, () => _sendMonthlyAll(_months[now.month])),
      const SizedBox(height: 8),
      _tplCard('🏆 تهنئة المتفوقين', 'إرسال تهنئة لأعلى 3 طلاب', AppTheme.warning, () => _sendExcellence()),
    ]));
  }

  Widget _bulkCard(String title, Color color, VoidCallback onTap) => Padding(padding: const EdgeInsets.all(14), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))), child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))), ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)), child: const Text('إرسال', style: TextStyle(color: Colors.white, fontSize: 12)))])));
  Widget _tplCard(String title, String sub, Color color, VoidCallback onTap) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(13), border: Border.all(color: color.withOpacity(0.18))), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))])), ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7)), child: const Text('إرسال', style: TextStyle(color: Colors.white, fontSize: 12)))]));
  Widget _tile(Student s, String info, Color c, VoidCallback onTap) { final isDark = Theme.of(context).brightness == Brightness.dark; return Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard, borderRadius: BorderRadius.circular(11), border: Border.all(color: c.withOpacity(0.2))), child: Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(s.name[0], style: TextStyle(color: c, fontWeight: FontWeight.bold)))), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text(info, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.bold))])), GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.chat, color: AppTheme.success, size: 18)))])); }

  Future<void> _sendBulk(List<Student> students, String type) async {
    for (final s in students) {
      final msg = type == 'debt' ? WhatsAppTemplates.debt(s.name, s.balance.abs().toStringAsFixed(0)) : WhatsAppTemplates.absence(s.name, s.groupName);
      await _send(s, msg);
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _sendMonthlyAll(String month) async {
    final students = await DatabaseHelper.instance.getStudents();
    for (final s in students) {
      final pct = await DatabaseHelper.instance.getAttendancePercentage(s.id!);
      await _send(s, WhatsAppTemplates.monthlyReport(s.name, month, pct.toStringAsFixed(0), s.balance.toStringAsFixed(0), '${s.xp}'));
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _sendExcellence() async {
    final students = await DatabaseHelper.instance.getStudents();
    for (final s in students.take(3)) {
      await _send(s, WhatsAppTemplates.excellence(s.name, s.level));
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}
