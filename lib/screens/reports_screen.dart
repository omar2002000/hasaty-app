import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

// ========================= التقارير =========================
class ReportsScreen extends StatefulWidget {
  const ReportsScreen();
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  Map<String, dynamic> _r = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final r = await DatabaseHelper.instance.getSmartReport();
    if (!mounted) return;
    setState(() { _r = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('التقارير الذكية'),
      actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () { setState(() => _loading = true); _load(); })],
      bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
        tabs: const [Tab(text: 'المالي'), Tab(text: 'الالتزام'), Tab(text: 'الذكي')]),
    ),
    body: _loading ? const LoadingWidget() : TabBarView(controller: _tab, children: [_financial(), _commitment(), _smart()]),
  );

  Widget _financial() {
    final income   = (_r['monthlyIncome']  ?? 0.0) as double;
    final expected = (_r['expectedIncome'] ?? 0.0) as double;
    final rate     = (_r['collectionRate'] ?? 0.0) as double;
    final debt     = (_r['totalDebt']      ?? 0.0) as double;
    final ds       = (_r['debtStudents']   as List<Student>?) ?? [];
    final now      = DateTime.now();
    final months   = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      _hdr('${months[now.month]} ${now.year}', Icons.calendar_month, AppTheme.primary),
      const SizedBox(height: 12),
      Row(children: [_bs('${income.toStringAsFixed(0)} ج', 'محصّل', AppTheme.success, Icons.trending_up), const SizedBox(width: 10), _bs('${expected.toStringAsFixed(0)} ج', 'متوقع', AppTheme.primary, Icons.calculate)]),
      const SizedBox(height: 10),
      Row(children: [_bs('${debt.toStringAsFixed(0)} ج', 'ديون', AppTheme.danger, Icons.money_off), const SizedBox(width: 10), _bs('${ds.length} طالب', 'مديونون', AppTheme.warning, Icons.warning_amber)]),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: (rate >= 80 ? AppTheme.success : rate >= 50 ? AppTheme.warning : AppTheme.danger).withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: (rate >= 80 ? AppTheme.success : rate >= 50 ? AppTheme.warning : AppTheme.danger).withOpacity(0.2))), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('نسبة التحصيل', style: TextStyle(fontWeight: FontWeight.bold)), Text('${rate.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: rate >= 80 ? AppTheme.success : rate >= 50 ? AppTheme.warning : AppTheme.danger))]),
        const SizedBox(height: 7),
        ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: (rate / 100).clamp(0.0, 1.0), backgroundColor: const Color(0xFFE2E8F0), color: rate >= 80 ? AppTheme.success : rate >= 50 ? AppTheme.warning : AppTheme.danger, minHeight: 11)),
      ])),
      if (ds.isNotEmpty) ...[const SizedBox(height: 14), const SectionHeader(title: 'الطلاب المديونون'), const SizedBox(height: 8), ...ds.map(_debtTile)],
    ]));
  }

  Widget _commitment() {
    final best = (_r['bestAttendance'] as List?) ?? [];
    final star = _r['weekStar'] as Student?;
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      if (star != null) Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [const Text('⭐', style: TextStyle(fontSize: 32)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('نجم الأسبوع', style: TextStyle(color: Colors.white70, fontSize: 12)), Text(star.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)), Text('${star.xp} XP — ${star.levelEmoji} ${star.level}', style: const TextStyle(color: Colors.white70, fontSize: 12))]))]),
      ),
      ActionTile(title: 'لوحة المتصدرين', subtitle: 'ترتيب الطلاب بالنقاط والحضور', icon: Icons.emoji_events, color: AppTheme.warning, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
      if (best.isEmpty) const EmptyState(icon: Icons.analytics, title: 'لا توجد بيانات حضور', subtitle: 'سجّل حصصاً لرؤية التقارير')
      else ...[const SectionHeader(title: 'الأكثر التزاماً'), const SizedBox(height: 8), ...best.asMap().entries.map((e) => _attTile(e.value['student'] as Student, e.value['percentage'] as double, e.key))],
    ]));
  }

  Widget _smart() {
    final risks  = (_r['riskStudents'] as List?) ?? [];
    final danger = risks.where((r) => r['risk'] == 'خطر').length;
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.danger.withOpacity(0.1), AppTheme.warning.withOpacity(0.05)]), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.danger.withOpacity(0.2))), child: Column(children: [
        Row(children: [const Icon(Icons.security, color: AppTheme.danger, size: 20), const SizedBox(width: 8), const Text('نظام كشف المخاطر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const Spacer(), if (danger > 0) StatusBadge(label: '$danger في خطر', color: AppTheme.danger, icon: Icons.warning)]),
        const SizedBox(height: 8), const Text('تحليل تلقائي لأداء الطلاب بناءً على الحضور والالتزام المالي', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.arrow_forward, size: 15, color: Colors.white), label: const Text('فتح تحليل المخاطر', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiskDetectionScreen())))),
      ])),
      const SizedBox(height: 10),
      ActionTile(title: 'لوحة المتصدرين', subtitle: 'XP والحضور والالتزام المالي', icon: Icons.emoji_events, color: AppTheme.warning, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
      if (risks.isNotEmpty) ...[
        const SectionHeader(title: '⚠️ تحتاج متابعة عاجلة'), const SizedBox(height: 8),
        ...risks.where((r) => r['risk'] == 'خطر').take(3).map((r) {
          final s = r['student'] as Student;
          return Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(11), border: Border.all(color: AppTheme.danger.withOpacity(0.2))),
            child: Row(children: [const Icon(Icons.warning, color: AppTheme.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))), const StatusBadge(label: 'خطر', color: AppTheme.danger)]));
        }),
      ],
    ]));
  }

  Widget _hdr(String t, IconData i, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: c.withOpacity(0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.15))), child: Row(children: [Icon(i, color: c, size: 16), const SizedBox(width: 7), Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c))]));
  Widget _bs(String v, String l, Color c, IconData i) => Expanded(child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: c.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 17), const SizedBox(height: 7), Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c)), Text(l, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))])));
  Widget _debtTile(Student s) => Container(margin: const EdgeInsets.only(bottom: 5), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.danger.withOpacity(0.15))), child: Row(children: [const Icon(Icons.warning_amber, color: AppTheme.danger, size: 15), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(s.groupName, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary))])), Text('${s.balance.abs().toStringAsFixed(0)} ج', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold))]));
  Widget _attTile(Student s, double pct, int rank) {
    const medals = ['🥇', '🥈', '🥉']; final c = pct >= 80 ? AppTheme.success : pct >= 60 ? AppTheme.warning : AppTheme.danger;
    return Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(11), border: Border.all(color: c.withOpacity(0.15))), child: Row(children: [Text(medals[rank], style: const TextStyle(fontSize: 19)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 3), LinearProgressIndicator(value: pct/100, color: c, backgroundColor: const Color(0xFFE2E8F0), minHeight: 5, borderRadius: BorderRadius.circular(3))])), const SizedBox(width: 8), Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: c, fontWeight: FontWeight.bold))]));
  }
}

// ========================= كشف المخاطر =========================
class RiskDetectionScreen extends StatefulWidget {
  const RiskDetectionScreen();
  @override
  _RiskDetectionScreenState createState() => _RiskDetectionScreenState();
}

class _RiskDetectionScreenState extends State<RiskDetectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _risks = [], _heat = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final students = await DatabaseHelper.instance.getStudents();
    final risks = <Map<String, dynamic>>[], heat = <Map<String, dynamic>>[];
    for (final s in students) {
      final pct = await DatabaseHelper.instance.getAttendancePercentage(s.id!);
      risks.add({'student': s, 'risk': s.riskLevel(pct), 'attendance': pct});
      heat.add({'student': s, 'debt': s.balance.abs(), 'attendance': pct});
    }
    risks.sort((a, b) { const o = {'خطر': 0, 'متأخر': 1, 'ملتزم': 2}; return (o[a['risk']] ?? 2).compareTo(o[b['risk']] ?? 2); });
    heat.sort((a, b) => (b['debt'] as double).compareTo(a['debt'] as double));
    if (!mounted) return;
    setState(() { _risks = risks; _heat = heat; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final d = _risks.where((r) => r['risk'] == 'خطر').length;
    final l = _risks.where((r) => r['risk'] == 'متأخر').length;
    final ok = _risks.where((r) => r['risk'] == 'ملتزم').length;
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text('كشف المخاطر'), bottom: const TabBar(labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white, tabs: [Tab(text: 'تصنيف الطلاب'), Tab(text: 'خريطة الديون')])),
      body: _loading ? const LoadingWidget() : Column(children: [
        Container(padding: const EdgeInsets.all(14), color: AppTheme.primary.withOpacity(0.04), child: Row(children: [
          _rs('خطر', d, AppTheme.danger, Icons.warning), _rs('متأخر', l, AppTheme.warning, Icons.access_time), _rs('ملتزم', ok, AppTheme.success, Icons.check_circle),
        ])),
        Expanded(child: TabBarView(children: [_riskTab(), _heatTab()])),
      ]),
    ));
  }

  Widget _rs(String l, int c, Color color, IconData i) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11), border: Border.all(color: color.withOpacity(0.2))), child: Column(children: [Icon(i, color: color, size: 18), const SizedBox(height: 3), Text('$c', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)), Text(l, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary))])));

  Widget _riskTab() => _risks.isEmpty ? const EmptyState(icon: Icons.security, title: 'لا توجد بيانات', subtitle: 'أضف طلاباً وسجّل الحضور')
      : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _risks.length, itemBuilder: (ctx, i) {
          final s = _risks[i]['student'] as Student; final risk = _risks[i]['risk'] as String; final pct = _risks[i]['attendance'] as double;
          final rc = risk == 'خطر' ? AppTheme.danger : risk == 'متأخر' ? AppTheme.warning : AppTheme.success;
          return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: rc.withOpacity(0.05), borderRadius: BorderRadius.circular(13), border: Border.all(color: rc.withOpacity(0.2))), child: Column(children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: rc.withOpacity(0.12), borderRadius: BorderRadius.circular(11)), child: Center(child: Text(s.name[0], style: TextStyle(color: rc, fontWeight: FontWeight.bold, fontSize: 15)))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(s.groupName, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))])),
              StatusBadge(label: risk, color: rc, icon: risk == 'خطر' ? Icons.warning : risk == 'متأخر' ? Icons.access_time : Icons.check),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _mi('الحضور', '${pct.toStringAsFixed(0)}%', pct >= 75 ? AppTheme.success : AppTheme.danger),
              const SizedBox(width: 7),
              _mi('الرصيد', '${s.balance.toStringAsFixed(0)} ج', s.balance >= 0 ? AppTheme.success : AppTheme.danger),
              const SizedBox(width: 7),
              _mi('XP', '${s.xp}', AppTheme.warning),
            ]),
          ]));
        });

  Widget _mi(String l, String v, Color c) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 5), decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(7)), child: Column(children: [Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 12)), Text(l, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary))])));

  Widget _heatTab() {
    if (_heat.isEmpty) return const EmptyState(icon: Icons.thermostat, title: 'لا توجد بيانات', subtitle: 'أضف طلاباً لرؤية خريطة الديون');
    final max = _heat.fold(0.0, (m, d) => (d['debt'] as double) > m ? d['debt'] as double : m);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(14), child: Row(children: [const Text('الديون: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)), Expanded(child: Container(height: 9, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.success, AppTheme.warning, AppTheme.danger]), borderRadius: BorderRadius.circular(5)))), const SizedBox(width: 7), const Text('عالي', style: TextStyle(fontSize: 10, color: AppTheme.danger))])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 14), itemCount: _heat.length, itemBuilder: (ctx, i) {
        final s = _heat[i]['student'] as Student; final debt = _heat[i]['debt'] as double; final pct = _heat[i]['attendance'] as double;
        final ratio = max > 0 ? debt / max : 0.0; final hc = Color.lerp(AppTheme.success, AppTheme.danger, ratio)!;
        return Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: hc.withOpacity(0.07), borderRadius: BorderRadius.circular(11), border: Border(left: BorderSide(color: hc, width: 4))),
          child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text(s.groupName, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(s.balance < 0 ? '${debt.toStringAsFixed(0)} ج دين' : 'لا دين', style: TextStyle(color: hc, fontWeight: FontWeight.bold, fontSize: 12)), Text('حضور ${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary))])]));
      })),
    ]);
  }
}

// ========================= لوحة المتصدرين =========================
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen();
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Student> _byXp = [], _byPay = [];
  List<Map<String, dynamic>> _byAtt = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final s = await DatabaseHelper.instance.getStudents();
    final att = <Map<String, dynamic>>[];
    for (final st in s) { final p = await DatabaseHelper.instance.getAttendancePercentage(st.id!); att.add({'student': st, 'pct': p}); }
    att.sort((a, b) => (b['pct'] as double).compareTo(a['pct'] as double));
    if (!mounted) return;
    setState(() { _byXp = s; _byAtt = att; _byPay = List.from(s)..sort((a, b) => b.balance.compareTo(a.balance)); _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('لوحة المتصدرين'), bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white, tabs: const [Tab(text: 'نقاط XP'), Tab(text: 'الحضور'), Tab(text: 'مالي')])),
    body: _loading ? const LoadingWidget() : TabBarView(controller: _tab, children: [
      _xpTab(), _attTab(), _payTab(),
    ]),
  );

  Widget _xpTab() => _byXp.isEmpty ? const EmptyState(icon: Icons.emoji_events, title: 'لا يوجد طلاب', subtitle: 'أضف طلاباً') : Column(children: [if (_byXp.length >= 3) _podium(_byXp[0], _byXp[1], _byXp.length > 2 ? _byXp[2] : null), Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 14), itemCount: _byXp.length, itemBuilder: (ctx, i) => _rank(i, _byXp[i], '${_byXp[i].xp} XP', AppTheme.warning)))]);
  Widget _attTab() => _byAtt.isEmpty ? const EmptyState(icon: Icons.how_to_reg, title: 'لا توجد بيانات', subtitle: 'سجّل الحضور') : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _byAtt.length, itemBuilder: (ctx, i) { final s = _byAtt[i]['student'] as Student; final p = _byAtt[i]['pct'] as double; return _rank(i, s, '${p.toStringAsFixed(0)}% حضور', p >= 80 ? AppTheme.success : p >= 60 ? AppTheme.warning : AppTheme.danger); });
  Widget _payTab() => _byPay.isEmpty ? const EmptyState(icon: Icons.payments, title: 'لا يوجد طلاب', subtitle: 'أضف طلاباً') : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _byPay.length, itemBuilder: (ctx, i) { final s = _byPay[i]; return _rank(i, s, '${s.balance.toStringAsFixed(0)} ج', s.balance >= 0 ? AppTheme.success : AppTheme.danger); });

  Widget _podium(Student f, Student s2, Student? t) => Container(
    padding: const EdgeInsets.all(18), margin: const EdgeInsets.all(14),
    decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.07), AppTheme.primaryLight.withOpacity(0.04)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withOpacity(0.1))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end, children: [
      _pod(s2, 2, 60), _pod(f, 1, 88), if (t != null) _pod(t, 3, 44) else const SizedBox(width: 60),
    ]),
  );

  Widget _pod(Student s, int rank, double h) {
    const medals = {1: '🥇', 2: '🥈', 3: '🥉'}; final colors = {1: AppTheme.warning, 2: Colors.grey, 3: const Color(0xFFCD7F32)}; final c = colors[rank]!;
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(medals[rank]!, style: const TextStyle(fontSize: 22)), const SizedBox(height: 3),
      Container(width: 36, height: 36, decoration: BoxDecoration(color: c.withOpacity(0.15), shape: BoxShape.circle), child: Center(child: Text(s.name[0], style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14)))),
      const SizedBox(height: 3),
      Text(s.name.split(' ').first, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text('${s.xp} XP', style: TextStyle(fontSize: 9, color: c)),
      const SizedBox(height: 4),
      Container(width: 56, height: h, decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(5)), border: Border.all(color: c.withOpacity(0.4))), child: Center(child: Text('$rank', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14)))),
    ]);
  }

  Widget _rank(int i, Student s, String info, Color c) {
    const medals = ['🥇', '🥈', '🥉']; final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: i < 3 ? c.withOpacity(0.06) : (isDark ? AppTheme.bgCardDark : AppTheme.bgCard), borderRadius: BorderRadius.circular(11), border: Border.all(color: i < 3 ? c.withOpacity(0.2) : const Color(0xFFE2E8F0))),
      child: Row(children: [
        SizedBox(width: 30, child: Center(child: i < 3 ? Text(medals[i], style: const TextStyle(fontSize: 18)) : Text('${i+1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)))),
        const SizedBox(width: 8),
        Container(width: 34, height: 34, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Center(child: Text(s.name[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)))),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text(s.groupName, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary))])),
        Text(info, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 12)),
      ]));
  }
}
