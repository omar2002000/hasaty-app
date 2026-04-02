import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Student> _byXp = [];
  List<Map<String, dynamic>> _byAttendance = [];
  List<Student> _byPayment = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  _load() async {
    final students = await DatabaseHelper.instance.getStudents();
    List<Map<String, dynamic>> attStats = [];
    for (final s in students) {
      final pct = await DatabaseHelper.instance.getAttendancePercentage(s.id!);
      attStats.add({'student': s, 'pct': pct});
    }
    attStats.sort((a, b) => (b['pct'] as double).compareTo(a['pct'] as double));
    final byPayment = List<Student>.from(students)..sort((a, b) => b.balance.compareTo(a.balance));

    setState(() { _byXp = students; _byAttendance = attStats; _byPayment = byPayment; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة المتصدرين'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
          tabs: [Tab(text: 'نقاط XP'), Tab(text: 'الحضور'), Tab(text: 'الالتزام المالي')],
        ),
      ),
      body: _loading ? LoadingWidget() : TabBarView(controller: _tab, children: [
        _xpTab(), _attendanceTab(), _paymentTab(),
      ]),
    );
  }

  Widget _xpTab() {
    if (_byXp.isEmpty) return EmptyState(icon: Icons.emoji_events, title: 'لا يوجد طلاب', subtitle: 'أضف طلاباً لرؤية الترتيب');
    return Column(children: [
      if (_byXp.length >= 3) _podium(_byXp[0], _byXp[1], _byXp.length > 2 ? _byXp[2] : null),
      Expanded(child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _byXp.length,
        itemBuilder: (ctx, i) => _rankTile(i, _byXp[i], '${_byXp[i].xp} XP', AppTheme.warning),
      )),
    ]);
  }

  Widget _attendanceTab() {
    if (_byAttendance.isEmpty) return EmptyState(icon: Icons.how_to_reg, title: 'لا توجد بيانات', subtitle: 'سجّل الحضور لرؤية الترتيب');
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _byAttendance.length,
      itemBuilder: (ctx, i) {
        final s = _byAttendance[i]['student'] as Student;
        final pct = _byAttendance[i]['pct'] as double;
        final color = pct >= 80 ? AppTheme.success : pct >= 60 ? AppTheme.warning : AppTheme.danger;
        return _rankTile(i, s, '${pct.toStringAsFixed(0)}% حضور', color);
      },
    );
  }

  Widget _paymentTab() {
    if (_byPayment.isEmpty) return EmptyState(icon: Icons.payments, title: 'لا يوجد طلاب', subtitle: 'أضف طلاباً لرؤية الترتيب');
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _byPayment.length,
      itemBuilder: (ctx, i) {
        final s = _byPayment[i];
        final color = s.balance >= 0 ? AppTheme.success : AppTheme.danger;
        return _rankTile(i, s, '${s.balance.toStringAsFixed(0)} ج رصيد', color);
      },
    );
  }

  Widget _podium(Student first, Student second, Student? third) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.08), AppTheme.primaryLight.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end, children: [
        _podiumItem(second, 2, 65),
        _podiumItem(first, 1, 90),
        if (third != null) _podiumItem(third, 3, 50) else SizedBox(width: 70),
      ]),
    );
  }

  Widget _podiumItem(Student s, int rank, double height) {
    final colors = {1: AppTheme.warning, 2: Colors.grey, 3: Color(0xFFCD7F32)};
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    final color = colors[rank]!;
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(medals[rank]!, style: TextStyle(fontSize: 24)),
      SizedBox(height: 4),
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
        child: Center(child: Text(s.name[0], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)))),
      SizedBox(height: 4),
      Text(s.name.split(' ').first, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text('${s.xp} XP', style: TextStyle(fontSize: 10, color: color)),
      SizedBox(height: 4),
      Container(width: 60, height: height, decoration: BoxDecoration(
        color: color.withOpacity(0.2), borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        border: Border.all(color: color.withOpacity(0.4)),
      ), child: Center(child: Text('$rank', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)))),
    ]);
  }

  Widget _rankTile(int index, Student s, String info, Color color) {
    final medals = ['🥇', '🥈', '🥉'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index < 3 ? color.withOpacity(0.06) : (isDark ? AppTheme.bgCardDark : AppTheme.bgCard),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: index < 3 ? color.withOpacity(0.2) : Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        SizedBox(width: 36, child: Center(child: index < 3
          ? Text(medals[index], style: TextStyle(fontSize: 20))
          : Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)))),
        SizedBox(width: 10),
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(s.name[0], style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)))),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(s.groupName, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ])),
        Text(info, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ]),
    );
  }
}
