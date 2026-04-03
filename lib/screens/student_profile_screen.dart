import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class StudentProfileScreen extends StatefulWidget {
  final Student student;
  const StudentProfileScreen({required this.student});
  @override
  _StudentProfileScreenState createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Student _s;
  List<AttendanceRecord> _att  = [];
  List<Payment>          _pay  = [];
  List<AcademicGrade>    _gr   = [];
  List<String>           _ach  = [];
  double _pct = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _s = widget.student; _tab = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final att = await db.getStudentAttendance(_s.id!);
    final pay = await db.getStudentPayments(_s.id!);
    final gr  = await db.getStudentGrades(_s.id!);
    final ach = await db.getStudentAchievements(_s.id!);
    final pct = await db.getAttendancePercentage(_s.id!);
    final upd = await db.getStudentById(_s.id!);
    if (!mounted) return;
    setState(() { _att = att; _pay = pay; _gr = gr; _ach = ach; _pct = pct; if (upd != null) _s = upd; _loading = false; });
  }

  Color get _lc {
    switch (_s.level) { case 'نجم': return AppTheme.warning; case 'متقدم': return AppTheme.purple; case 'متوسط': return AppTheme.primaryLight; default: return AppTheme.success; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? const LoadingWidget() : NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 260, pinned: true, backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: SafeArea(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(width: 68, height: 68, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18)),
                      child: Center(child: Text(_s.name[0], style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)))),
                    const SizedBox(height: 10),
                    Text(_s.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(_s.groupName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _pill('📞 ${_s.phone}', Colors.white),
                      const SizedBox(width: 8),
                      _pill('${_s.levelEmoji} ${_s.level}', _lc),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Text('XP: ${_s.xp}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(width: 8),
                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (_s.xp / _s.nextLevelXp).clamp(0.0, 1.0), backgroundColor: Colors.white.withOpacity(0.2), color: Colors.white, minHeight: 6))),
                      const SizedBox(width: 8),
                      Text('${_s.nextLevelXp}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
                  ]),
                )),
              ),
            ),
            bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
              tabs: const [Tab(text: 'الملف'), Tab(text: 'الحضور'), Tab(text: 'الدفعات')]),
          ),
        ],
        body: TabBarView(controller: _tab, children: [_profileTab(), _attTab(), _payTab()]),
      ),
    );
  }

  Widget _profileTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      Row(children: [
        StatCard(title: 'الرصيد',   value: '${_s.balance.toStringAsFixed(0)} ج', icon: Icons.account_balance_wallet, color: _s.balance >= 0 ? AppTheme.success : AppTheme.danger),
        const SizedBox(width: 8),
        StatCard(title: 'الحضور',   value: '${_pct.toStringAsFixed(0)}%',         icon: Icons.check_circle_outline,   color: _pct >= 75 ? AppTheme.success : AppTheme.warning),
        const SizedBox(width: 8),
        StatCard(title: 'نقاط XP',  value: '${_s.xp}',                            icon: Icons.stars,                  color: AppTheme.warning),
      ]),
      const SizedBox(height: 16),
      const SectionHeader(title: '🎖️ الإنجازات'),
      const SizedBox(height: 8),
      _ach.isEmpty
          ? Container(padding: const EdgeInsets.all(14), width: double.infinity, decoration: BoxDecoration(color: AppTheme.textSecondary.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
              child: const Text('لا يوجد إنجازات بعد — استمر في الحضور والدفع!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center))
          : Wrap(spacing: 8, runSpacing: 8, children: _ach.map((id) {
              final a = Achievements.getById(id);
              if (a == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.warning.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(a.emoji, style: const TextStyle(fontSize: 15)), const SizedBox(width: 5),
                  Text(a.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              );
            }).toList()),
      if (_gr.isNotEmpty) ...[
        const SizedBox(height: 16),
        const SectionHeader(title: '📝 آخر التقييمات'),
        const SizedBox(height: 8),
        ..._gr.take(5).map((g) {
          final gc = g.grade == 'excellent' ? AppTheme.success : g.grade == 'good' ? AppTheme.accent : g.grade == 'acceptable' ? AppTheme.warning : AppTheme.danger;
          return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: gc.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: gc.withOpacity(0.2))),
            child: Row(children: [
              Text(g.gradeEmoji, style: const TextStyle(fontSize: 18)), const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${g.typeLabel} — ${g.gradeLabel}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (g.sessionTopic.isNotEmpty) Text(g.sessionTopic, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ])),
              Text(g.date, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ]));
        }),
      ],
    ]),
  );

  Widget _attTab() => _att.isEmpty
      ? const EmptyState(icon: Icons.event_busy, title: 'لا يوجد سجل حضور', subtitle: 'سيظهر هنا بعد تسجيل أول حصة')
      : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _att.length, itemBuilder: (ctx, i) {
          final r = _att[i];
          return ListTile(
            leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: (r.present ? AppTheme.success : AppTheme.danger).withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(r.present ? Icons.check : Icons.close, color: r.present ? AppTheme.success : AppTheme.danger, size: 16)),
            title: Text(r.present ? 'حاضر' : 'غائب', style: TextStyle(color: r.present ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.bold)),
            subtitle: Text(r.groupName),
            trailing: Text(r.date, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          );
        });

  Widget _payTab() => _pay.isEmpty
      ? const EmptyState(icon: Icons.receipt_long, title: 'لا توجد دفعات', subtitle: 'سيظهر هنا تاريخ المدفوعات')
      : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _pay.length, itemBuilder: (ctx, i) {
          final p = _pay[i];
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.success.withOpacity(0.15))),
            child: Row(children: [
              Container(width: 34, height: 34, decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.payments, color: AppTheme.success, size: 17)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p.amount.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 14)),
                if (p.note.isNotEmpty) Text(p.note, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ])),
              Text(p.date, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ]));
        });

  Widget _pill(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 11)),
  );
}
