import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class WhatsAppAutomationScreen extends StatefulWidget {
  @override
  _WhatsAppAutomationScreenState createState() => _WhatsAppAutomationScreenState();
}

class _WhatsAppAutomationScreenState extends State<WhatsAppAutomationScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Student> _debtStudents = [];
  List<Student> _absentStudents = [];
  List<Student> _underStudents = [];
  bool _loading = true;

  final months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  _load() async {
    final debts = await DatabaseHelper.instance.getStudentsWithDebt();
    final students = await DatabaseHelper.instance.getStudents();
    List<Student> absent = [], under = [];

    for (final s in students) {
      final pct = await DatabaseHelper.instance.getAttendancePercentage(s.id!);
      if (pct < 60 && pct > 0) absent.add(s);
      final grades = await DatabaseHelper.instance.getStudentGrades(s.id!);
      if (grades.where((g) => g.grade == 'weak').length >= 2) under.add(s);
    }

    setState(() { _debtStudents = debts; _absentStudents = absent; _underStudents = under; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مركز واتساب التلقائي'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'مالي (${_debtStudents.length})'),
            Tab(text: 'غياب (${_absentStudents.length})'),
            Tab(text: 'أكاديمي'),
          ],
        ),
      ),
      body: _loading ? LoadingWidget() : TabBarView(controller: _tab, children: [
        _debtTab(), _absenceTab(), _academicTab(),
      ]),
    );
  }

  // ===== تبويب المالي =====
  Widget _debtTab() {
    final now = DateTime.now();
    return Column(children: [
      // إرسال للكل
      Padding(
        padding: EdgeInsets.all(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.warning.withOpacity(0.15), AppTheme.danger.withOpacity(0.08)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
          ),
          child: Column(children: [
            Row(children: [
              Icon(Icons.send_to_mobile, color: AppTheme.warning, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('إرسال تذكير مالي للكل (${_debtStudents.length} طالب)', style: TextStyle(fontWeight: FontWeight.bold))),
            ]),
            SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              icon: Icon(Icons.campaign, size: 16, color: Colors.white),
              label: Text('إرسال لجميع المديونين', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _debtStudents.isEmpty ? null : () => _sendBulk(_debtStudents, 'debt'),
            )),
          ]),
        ),
      ),

      Expanded(child: _debtStudents.isEmpty
        ? EmptyState(icon: Icons.check_circle_outline, title: 'لا يوجد مديونون', subtitle: 'جميع الطلاب ملتزمون مالياً 🎉')
        : ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _debtStudents.length,
            itemBuilder: (ctx, i) => _studentMessageTile(
              _debtStudents[i], 'debt',
              'دين: ${_debtStudents[i].balance.abs().toStringAsFixed(0)} ج.م',
              AppTheme.danger,
              extra: {'amount': _debtStudents[i].balance.abs().toStringAsFixed(0), 'month': months[now.month]},
            ),
          )),
    ]);
  }

  // ===== تبويب الغياب =====
  Widget _absenceTab() => Column(children: [
    Padding(
      padding: EdgeInsets.all(16),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.danger.withOpacity(0.2))),
        child: Row(children: [
          Icon(Icons.info_outline, color: AppTheme.danger, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text('الطلاب الذين تقل نسبة حضورهم عن 60%', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
        ]),
      ),
    ),
    Expanded(child: _absentStudents.isEmpty
      ? EmptyState(icon: Icons.how_to_reg, title: 'جميع الطلاب ملتزمون', subtitle: 'لا يوجد طلاب بنسبة غياب عالية 🎉')
      : ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: _absentStudents.length,
          itemBuilder: (ctx, i) {
            final s = _absentStudents[i];
            return FutureBuilder<double>(
              future: DatabaseHelper.instance.getAttendancePercentage(s.id!),
              builder: (ctx, snap) => _studentMessageTile(
                s, 'absence',
                'حضور: ${snap.data?.toStringAsFixed(0) ?? '?'}%',
                AppTheme.warning,
                extra: {'group': s.groupName},
              ),
            );
          },
        )),
  ]);

  // ===== تبويب الأكاديمي =====
  Widget _academicTab() {
    final now = DateTime.now();
    return Column(children: [
      Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          _templateCard('📊 تقرير شهري للكل', 'إرسال ملخص الأداء لكل الطلاب', AppTheme.primary, () => _sendMonthlyReportAll(months[now.month])),
          SizedBox(height: 8),
          _templateCard('🏆 تهنئة المتفوقين', 'إرسال تهنئة لأعلى 3 طلاب XP', AppTheme.warning, () => _sendExcellenceMessages()),
          SizedBox(height: 8),
          _templateCard('⚠️ تنبيه المقصرين', 'إرسال تنبيه للطلاب ذوي التقييمات الضعيفة', AppTheme.danger, () => _sendWeakAlerts()),
        ]),
      ),
    ]);
  }

  Widget _templateCard(String title, String subtitle, Color color, VoidCallback onTap) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ])),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
          child: Text('إرسال', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _studentMessageTile(Student s, String templateId, String info, Color color, {Map<String, String> extra = const {}}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(s.name[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)))),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(info, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ])),
        GestureDetector(
          onTap: () => _sendMessage(s, templateId, extra),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.chat, color: AppTheme.success, size: 20),
          ),
        ),
      ]),
    );
  }

  _buildWhatsAppUrl(Student s, String templateId, Map<String, String> extra) {
    final phone = s.phone.startsWith('0') ? s.phone.substring(1) : s.phone;
    final template = WhatsAppTemplates.all.firstWhere((t) => t.id == templateId, orElse: () => WhatsAppTemplates.all.first);
    final params = {'name': s.name, 'group': s.groupName, ...extra};
    final message = template.buildMessage(params);
    return "https://wa.me/20$phone?text=${Uri.encodeComponent(message)}";
  }

  _sendMessage(Student s, String templateId, Map<String, String> extra) async {
    final url = _buildWhatsAppUrl(s, templateId, extra);
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  _sendBulk(List<Student> students, String templateId) async {
    for (final s in students) {
      await _sendMessage(s, templateId, {'amount': s.balance.abs().toStringAsFixed(0)});
      await Future.delayed(Duration(seconds: 2));
    }
  }

  _sendMonthlyReportAll(String month) async {
    final students = await DatabaseHelper.instance.getStudents();
    for (final s in students) {
      final pct = await DatabaseHelper.instance.getAttendancePercentage(s.id!);
      await _sendMessage(s, 'monthly_report', {
        'month': month, 'attendance': pct.toStringAsFixed(0),
        'balance': s.balance.toStringAsFixed(0), 'xp': '${s.xp}',
      });
      await Future.delayed(Duration(seconds: 2));
    }
  }

  _sendExcellenceMessages() async {
    final students = await DatabaseHelper.instance.getStudents();
    final top3 = students.take(3).toList();
    for (final s in top3) {
      await _sendMessage(s, 'excellence', {'level': s.level});
      await Future.delayed(Duration(seconds: 2));
    }
  }

  _sendWeakAlerts() async {
    for (final s in _underStudents) {
      await _sendMessage(s, 'grade_weak', {'grade': 'ضعيف', 'type': 'التقييمات الأخيرة'});
      await Future.delayed(Duration(seconds: 2));
    }
  }
}
