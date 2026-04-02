import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class StudentProfileScreen extends StatefulWidget {
  final Student student;
  StudentProfileScreen({required this.student});
  @override
  _StudentProfileScreenState createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Student _student;
  List<AttendanceRecord> _attendance = [];
  List<Payment> _payments = [];
  List<String> _achievements = [];
  double _pct = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  _load() async {
    final att = await DatabaseHelper.instance.getStudentAttendance(_student.id!);
    final pay = await DatabaseHelper.instance.getStudentPayments(_student.id!);
    final ach = await DatabaseHelper.instance.getStudentAchievements(_student.id!);
    final pct = await DatabaseHelper.instance.getAttendancePercentage(_student.id!);
    final updated = await DatabaseHelper.instance.getStudentById(_student.id!);
    setState(() {
      _attendance = att; _payments = pay; _achievements = ach; _pct = pct;
      if (updated != null) _student = updated;
      _loading = false;
    });
  }

  Color get _levelColor {
    switch (_student.level) {
      case 'نجم': return AppTheme.warning;
      case 'متقدم': return AppTheme.purple;
      case 'متوسط': return AppTheme.primaryLight;
      default: return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: _loading ? LoadingWidget() : NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    // صورة رمزية كبيرة
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Center(child: Text(_student.name[0], style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
                    ),
                    SizedBox(height: 12),
                    Text(_student.name, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(_student.groupName, style: TextStyle(color: Colors.white70, fontSize: 13)),
                    SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _infoPill('📞 ${_student.phone}', Colors.white),
                      SizedBox(width: 8),
                      _infoPill('${_student.levelEmoji} ${_student.level}', _levelColor),
                    ]),
                    SizedBox(height: 12),
                    // XP Progress
                    Row(children: [
                      Text('XP: ${_student.xp}', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      SizedBox(width: 8),
                      Expanded(child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_student.xp / _student.nextLevelXp).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withOpacity(0.2),
                          color: Colors.white,
                          minHeight: 6,
                        ),
                      )),
                      SizedBox(width: 8),
                      Text('${_student.nextLevelXp}', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
                  ]),
                )),
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              labelColor: Colors.white, unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: [Tab(text: 'الملف'), Tab(text: 'الحضور'), Tab(text: 'الدفعات')],
            ),
          ),
        ],
        body: TabBarView(controller: _tab, children: [
          _profileTab(isDark),
          _attendanceTab(),
          _paymentsTab(),
        ]),
      ),
    );
  }

  Widget _profileTab(bool isDark) => SingleChildScrollView(
    padding: EdgeInsets.all(20),
    child: Column(children: [
      // بطاقات الإحصائيات
      Row(children: [
        StatCard(title: 'الرصيد', value: '${_student.balance.toStringAsFixed(0)} ج', icon: Icons.account_balance_wallet, color: _student.balance >= 0 ? AppTheme.success : AppTheme.danger),
        SizedBox(width: 10),
        StatCard(title: 'الحضور', value: '${_pct.toStringAsFixed(0)}%', icon: Icons.check_circle_outline, color: _pct >= 75 ? AppTheme.success : AppTheme.warning),
        SizedBox(width: 10),
        StatCard(title: 'نقاط XP', value: '${_student.xp}', icon: Icons.stars, color: AppTheme.warning),
      ]),
      SizedBox(height: 20),

      // الإنجازات
      SectionHeader(title: '🎖️ الإنجازات'),
      SizedBox(height: 8),
      if (_achievements.isEmpty)
        Container(
          padding: EdgeInsets.all(16), width: double.infinity,
          decoration: BoxDecoration(color: AppTheme.textSecondary.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
          child: Text('لا يوجد إنجازات بعد — استمر في الحضور والدفع المنتظم!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        )
      else
        Wrap(spacing: 8, runSpacing: 8, children: _achievements.map((id) {
          final a = Achievements.getById(id);
          if (a == null) return SizedBox.shrink();
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.warning.withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(a.emoji, style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(a.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          );
        }).toList()),
    ]),
  );

  Widget _attendanceTab() => _attendance.isEmpty
    ? EmptyState(icon: Icons.event_busy, title: 'لا يوجد سجل حضور', subtitle: 'سيظهر هنا بعد تسجيل أول حصة')
    : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _attendance.length,
        itemBuilder: (ctx, i) {
          final r = _attendance[i];
          return ListTile(
            leading: Container(width: 36, height: 36, decoration: BoxDecoration(
              color: (r.present ? AppTheme.success : AppTheme.danger).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(r.present ? Icons.check : Icons.close, color: r.present ? AppTheme.success : AppTheme.danger, size: 18)),
            title: Text(r.present ? 'حاضر' : 'غائب', style: TextStyle(color: r.present ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.bold)),
            subtitle: Text(r.groupName),
            trailing: Text(r.date, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          );
        },
      );

  Widget _paymentsTab() => _payments.isEmpty
    ? EmptyState(icon: Icons.receipt_long, title: 'لا توجد دفعات', subtitle: 'سيظهر هنا تاريخ المدفوعات')
    : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _payments.length,
        itemBuilder: (ctx, i) {
          final p = _payments[i];
          return Container(
            margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.success.withOpacity(0.15))),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.payments, color: AppTheme.success, size: 18)),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p.amount.toStringAsFixed(0)} ج.م', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 15)),
                if (p.note.isNotEmpty) Text(p.note, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ])),
              Text(p.date, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          );
        },
      );

  Widget _infoPill(String text, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(color: color == Colors.white ? Colors.white : color, fontSize: 11)),
  );
}
