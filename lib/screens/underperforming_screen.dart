import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class UnderperformingScreen extends StatefulWidget {
  @override
  _UnderperformingScreenState createState() => _UnderperformingScreenState();
}

class _UnderperformingScreenState extends State<UnderperformingScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  _load() async {
    final all = await DatabaseHelper.instance.getStudents();
    List<Map<String, dynamic>> result = [];

    for (final s in all) {
      final pct = await DatabaseHelper.instance.getAttendancePercentage(s.id!);
      final grades = await DatabaseHelper.instance.getStudentGrades(s.id!);
      final weakCount = grades.where((g) => g.grade == 'weak').length;
      final academicSummary = await DatabaseHelper.instance.getStudentAcademicSummary(s.id!);

      List<String> issues = [];
      if (pct < 60 && pct > 0) issues.add('غياب متكرر (${pct.toStringAsFixed(0)}%)');
      if (weakCount >= 2) issues.add('$weakCount تقييمات ضعيفة');
      if (s.balance < -300) issues.add('دين متراكم');

      if (issues.isNotEmpty) {
        result.add({
          'student': s,
          'attendance': pct,
          'weakCount': weakCount,
          'issues': issues,
          'academicAvg': academicSummary['average'],
        });
      }
    }

    // ترتيب حسب عدد المشاكل
    result.sort((a, b) => (b['issues'] as List).length.compareTo((a['issues'] as List).length));
    setState(() { _students = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('فلتر المقصرين'),
        backgroundColor: AppTheme.danger,
        actions: [
          if (_students.isNotEmpty)
            TextButton(
              onPressed: _sendAllAlerts,
              child: Text('تنبيه الكل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading ? LoadingWidget() : _students.isEmpty
        ? EmptyState(icon: Icons.verified_user, title: 'لا يوجد مقصرون', subtitle: 'جميع الطلاب ملتزمون 🎉')
        : Column(children: [
            // ملخص
            Container(
              padding: EdgeInsets.all(14),
              color: AppTheme.danger.withOpacity(0.05),
              child: Row(children: [
                Icon(Icons.warning_amber, color: AppTheme.danger, size: 18),
                SizedBox(width: 8),
                Text('${_students.length} طالب يحتاجون متابعة عاجلة', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger)),
              ]),
            ),
            Expanded(child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (ctx, i) => _studentCard(_students[i]),
            )),
          ]),
    );
  }

  Widget _studentCard(Map<String, dynamic> data) {
    final s = data['student'] as Student;
    final issues = data['issues'] as List<String>;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: AppTheme.danger.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(s.name[0], style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 18)))),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(s.groupName, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('${issues.length} مشكلة', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
        SizedBox(height: 10),

        // المشاكل
        Wrap(spacing: 6, runSpacing: 4, children: issues.map((issue) => Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.danger.withOpacity(0.2))),
          child: Text(issue, style: TextStyle(fontSize: 11, color: AppTheme.danger)),
        )).toList()),

        SizedBox(height: 10),
        Row(children: [
          Expanded(child: _actionBtn('إرسال تنبيه', Icons.warning_amber, AppTheme.warning, () => _sendAlert(s))),
          SizedBox(width: 8),
          Expanded(child: _actionBtn('واتساب', Icons.chat, AppTheme.success, () => _openWhatsApp(s))),
        ]),
      ]),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) => ElevatedButton.icon(
    icon: Icon(icon, size: 14, color: Colors.white),
    label: Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
    style: ElevatedButton.styleFrom(backgroundColor: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.symmetric(vertical: 8)),
    onPressed: onTap,
  );

  _sendAlert(Student s) async {
    final p = s.phone.startsWith('0') ? s.phone.substring(1) : s.phone;
    final msg = Uri.encodeComponent('⚠️ تنبيه مهم\nأهلاً ولي أمر ${s.name}،\nنُحيطكم علماً بأن هناك ملاحظات تخص نجلكم تحتاج متابعة.\nيرجى التواصل معنا في أقرب وقت.\nمعلمكم: مستر نصر علي 📚');
    final url = "https://wa.me/20$p?text=$msg";
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  _openWhatsApp(Student s) async {
    final p = s.phone.startsWith('0') ? s.phone.substring(1) : s.phone;
    final url = "https://wa.me/20$p";
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  _sendAllAlerts() async {
    for (final data in _students) {
      await _sendAlert(data['student'] as Student);
      await Future.delayed(Duration(seconds: 2));
    }
  }
}
