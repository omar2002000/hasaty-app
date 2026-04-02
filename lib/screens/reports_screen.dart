import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/index.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'risk_detection_screen.dart';
import 'leaderboard_screen.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  Map<String, dynamic> _report = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  _load() async {
    final r = await DatabaseHelper.instance.getSmartReport();
    setState(() { _report = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('التقارير الذكية'),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: Colors.white), onPressed: () { setState(() => _loading = true); _load(); }),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
          tabs: [Tab(text: 'المالي'), Tab(text: 'الالتزام'), Tab(text: 'الذكي')],
        ),
      ),
      body: _loading ? LoadingWidget() : TabBarView(controller: _tab, children: [
        _financialTab(), _commitmentTab(), _smartTab(),
      ]),
    );
  }

  Widget _financialTab() {
    final income = (_report['monthlyIncome'] ?? 0.0) as double;
    final expected = (_report['expectedIncome'] ?? 0.0) as double;
    final rate = (_report['collectionRate'] ?? 0.0) as double;
    final debt = (_report['totalDebt'] ?? 0.0) as double;
    final debtStudents = (_report['debtStudents'] as List<Student>?) ?? [];
    final now = DateTime.now();
    final months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

    return SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
      _monthHeader('${months[now.month]} ${now.year}'),
      SizedBox(height: 14),
      Row(children: [
        _statBox('${income.toStringAsFixed(0)} ج', 'محصّل فعلياً', AppTheme.success, Icons.trending_up),
        SizedBox(width: 10),
        _statBox('${expected.toStringAsFixed(0)} ج', 'متوقع الشهر', AppTheme.primary, Icons.calculate),
      ]),
      SizedBox(height: 10),
      Row(children: [
        _statBox('${debt.toStringAsFixed(0)} ج', 'إجمالي الديون', AppTheme.danger, Icons.money_off),
        SizedBox(width: 10),
        _statBox('${debtStudents.length} طالب', 'مديونون', AppTheme.warning, Icons.warning_amber),
      ]),
      SizedBox(height: 14),

      // نسبة التحصيل
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (rate >= 80 ? AppTheme.success : rate >= 50 ? AppTheme.warning : AppTheme.danger).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (rate >= 80 ? AppTheme.success : rate >= 50 ? AppTheme.warning : AppTheme.danger).withOpacity(0.2)),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('نسبة التحصيل', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${rate.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: rate >= 80 ? AppTheme.success : rate >= 50 ? AppTheme.warning : AppTheme.danger)),
          ]),
          SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
            value: (rate / 100).clamp(0.0, 1.0),
            backgroundColor: Color(0xFFE2E8F0),
            color: rate >= 80 ? AppTheme.success : rate >= 50 ? AppTheme.warning : AppTheme.danger,
            minHeight: 12,
          )),
          SizedBox(height: 6),
          Text(rate >= 80 ? '🎉 ممتاز! تحصيل عالٍ هذا الشهر' : rate >= 50 ? '⚠️ تحصيل متوسط — تابع المديونين' : '🚨 تحصيل منخفض — يحتاج متابعة عاجلة',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
      ),

      if (debtStudents.isNotEmpty) ...[
        SizedBox(height: 16),
        SectionHeader(title: 'الطلاب المديونون'),
        SizedBox(height: 8),
        ...debtStudents.map((s) => _debtTile(s)),
      ],
    ]));
  }

  Widget _commitmentTab() {
    final best = (_report['bestAttendance'] as List?) ?? [];
    final worst = (_report['mostAbsent'] as List?) ?? [];
    final star = _report['weekStar'] as Student?;

    return SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
      if (star != null) _starCard(star),
      SizedBox(height: 16),
      ActionTile(
        title: 'لوحة المتصدرين', subtitle: 'ترتيب الطلاب بالنقاط والحضور',
        icon: Icons.emoji_events, color: AppTheme.warning,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen())),
      ),
      SizedBox(height: 8),
      if (best.isEmpty)
        EmptyState(icon: Icons.analytics, title: 'لا توجد بيانات حضور', subtitle: 'سجّل حصصاً لرؤية التقارير')
      else ...[
        SectionHeader(title: 'الأكثر التزاماً', action: 'لوحة كاملة', onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen()))),
        SizedBox(height: 8),
        ...best.asMap().entries.map((e) => _attendanceTile(e.value['student'] as Student, e.value['percentage'] as double, e.key)),
        SizedBox(height: 16),
        SectionHeader(title: 'الأكثر غياباً'),
        SizedBox(height: 8),
        ...worst.asMap().entries.map((e) => _absenceTile(e.value['student'] as Student, e.value['percentage'] as double)),
      ],
    ]));
  }

  Widget _smartTab() {
    final riskStudents = (_report['riskStudents'] as List?) ?? [];
    final danger = riskStudents.where((r) => r['risk'] == 'خطر').length;

    return SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
      // بطاقة كشف المخاطر
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.danger.withOpacity(0.1), AppTheme.warning.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
        ),
        child: Column(children: [
          Row(children: [
            Icon(Icons.security, color: AppTheme.danger, size: 22),
            SizedBox(width: 8),
            Text('نظام كشف المخاطر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Spacer(),
            if (danger > 0) StatusBadge(label: '$danger في خطر', color: AppTheme.danger, icon: Icons.warning),
          ]),
          SizedBox(height: 10),
          Text('تحليل تلقائي لأداء الطلاب بناءً على الحضور والالتزام المالي', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            icon: Icon(Icons.arrow_forward, size: 16, color: Colors.white),
            label: Text('فتح تحليل المخاطر', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RiskDetectionScreen())),
          )),
        ]),
      ),
      SizedBox(height: 12),

      ActionTile(
        title: 'خريطة الديون الحرارية', subtitle: 'تصور بصري لحجم ديون الطلاب',
        icon: Icons.thermostat, color: AppTheme.warning,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RiskDetectionScreen())),
      ),
      ActionTile(
        title: 'لوحة المتصدرين', subtitle: 'XP والحضور والالتزام المالي',
        icon: Icons.emoji_events, color: AppTheme.warning,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen())),
      ),

      if (riskStudents.isNotEmpty) ...[
        SizedBox(height: 8),
        SectionHeader(title: '⚠️ تحتاج متابعة عاجلة'),
        SizedBox(height: 8),
        ...riskStudents.where((r) => r['risk'] == 'خطر').take(3).map((r) {
          final s = r['student'] as Student;
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.warning, color: AppTheme.danger, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold))),
              StatusBadge(label: 'خطر', color: AppTheme.danger),
            ]),
          );
        }),
      ],
    ]));
  }

  Widget _monthHeader(String title) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.primary.withOpacity(0.15))),
    child: Row(children: [Icon(Icons.calendar_month, color: AppTheme.primary, size: 16), SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary))]),
  );

  Widget _statBox(String value, String label, Color color, IconData icon) => Expanded(child: Container(
    padding: EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ]),
  ));

  Widget _debtTile(Student s) => Container(
    margin: EdgeInsets.only(bottom: 6), padding: EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.danger.withOpacity(0.15))),
    child: Row(children: [
      Icon(Icons.warning_amber, color: AppTheme.danger, size: 16), SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(s.groupName, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ])),
      Text('${s.balance.abs().toStringAsFixed(0)} ج', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _starCard(Student s) => Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Text('⭐', style: TextStyle(fontSize: 36)),
      SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('نجم الأسبوع', style: TextStyle(color: Colors.white70, fontSize: 12)),
        Text(s.name, style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        Text('${s.xp} XP — ${s.levelEmoji} ${s.level}', style: TextStyle(color: Colors.white70, fontSize: 12)),
      ])),
    ]),
  );

  Widget _attendanceTile(Student s, double pct, int rank) {
    final medals = ['🥇', '🥈', '🥉'];
    final color = pct >= 80 ? AppTheme.success : pct >= 60 ? AppTheme.warning : AppTheme.danger;
    return Container(
      margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.15))),
      child: Row(children: [
        Text(medals[rank], style: TextStyle(fontSize: 20)), SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          SizedBox(height: 4),
          LinearProgressIndicator(value: pct/100, color: color, backgroundColor: Color(0xFFE2E8F0), minHeight: 5, borderRadius: BorderRadius.circular(3)),
        ])),
        SizedBox(width: 10),
        Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _absenceTile(Student s, double pct) {
    final ab = 100 - pct;
    return Container(
      margin: EdgeInsets.only(bottom: 6), padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.danger.withOpacity(0.1))),
      child: Row(children: [
        Icon(Icons.person_off, color: AppTheme.danger, size: 18), SizedBox(width: 8),
        Expanded(child: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Text('${ab.toStringAsFixed(0)}% غياب', style: TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
