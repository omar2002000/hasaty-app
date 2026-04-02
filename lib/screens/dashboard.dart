import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import 'students_screen.dart';
import 'groups_screen.dart';
import 'financial_report_screen.dart';
import 'honor_board_screen.dart';
import 'smart_reports_screen.dart';
import 'gamification_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int studentCount = 0;
  double totalDebt = 0;
  double monthlyIncome = 0;
  List<Student> topStudents = [];
  List<Student> debtStudents = [];
  bool _isDark = false;

  @override
  void initState() { super.initState(); _refreshData(); }

  void _refreshData() async {
    final students = await DatabaseHelper.instance.getStudents();
    final income = await DatabaseHelper.instance.getTotalCollectedThisMonth();
    final debts = await DatabaseHelper.instance.getStudentsWithDebt();
    setState(() {
      studentCount = students.length;
      totalDebt = students.where((s) => s.balance < 0).fold(0, (sum, s) => sum + s.balance);
      monthlyIncome = income;
      topStudents = students.take(3).toList();
      debtStudents = debts.take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark ? Color(0xFF1A1A2E) : Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(children: [
          Text("مرحباً مستر نصر علي 👋",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text("معلم اللغة الإنجليزية",
              style: TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
        centerTitle: true,
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            onPressed: () => setState(() => _isDark = !_isDark),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ===== الإحصائيات =====
          _sectionTitle("إحصائيات سريعة"),
          SizedBox(height: 10),
          Row(children: [
            _statCard("الطلاب", studentCount.toString(), Colors.blue, Icons.people),
            SizedBox(width: 8),
            _statCard("ديون عليهم", "${totalDebt.abs().toStringAsFixed(0)} ج", Colors.red, Icons.money_off),
            SizedBox(width: 8),
            _statCard("هذا الشهر", "${monthlyIncome.toStringAsFixed(0)} ج", Colors.green, Icons.attach_money),
          ]),

          // ===== تنبيه الديون =====
          if (debtStudents.isNotEmpty) ...[
            SizedBox(height: 16),
            _sectionTitle("⚠️ طلاب بحاجة للمتابعة"),
            SizedBox(height: 8),
            ...debtStudents.map((s) => _debtAlert(s)),
          ],

          // ===== لوحة الشرف =====
          if (topStudents.isNotEmpty) ...[
            SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _sectionTitle("🏆 لوحة الشرف"),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GamificationScreen())),
                child: Text("التفاصيل"),
              ),
            ]),
            SizedBox(height: 8),
            Row(children: List.generate(topStudents.length, (i) => Expanded(child: _honorCard(topStudents[i], i)))),
          ],

          // ===== أزرار التحكم =====
          SizedBox(height: 20),
          _sectionTitle("لوحة التحكم"),
          SizedBox(height: 12),

          _actionBtn("بدء حصة (تحضير وخصم)", Icons.play_circle_fill, Colors.green, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => GroupsScreen())).then((_) => _refreshData());
          }),
          _actionBtn("إدارة الطلاب والكروت", Icons.people, Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => StudentsScreen())).then((_) => _refreshData());
          }),
          _actionBtn("إدارة المجموعات", Icons.account_tree_rounded, Colors.orange, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => GroupsScreen())).then((_) => _refreshData());
          }),
          _actionBtn("التقارير الذكية", Icons.analytics, Colors.purple, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SmartReportsScreen()));
          }),
          _actionBtn("التقرير المالي الشهري", Icons.bar_chart, Colors.teal, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => FinancialReportScreen())).then((_) => _refreshData());
          }),
          _actionBtn("نظام التحفيز والمستويات", Icons.emoji_events, Colors.amber, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => GamificationScreen()));
          }),
          _actionBtn("لوحة شرف الطلاب", Icons.star, Colors.pink, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => HonorBoardScreen()));
          }),

          SizedBox(height: 20),
          Center(child: Text("تطبيق حصتي — الإصدار 3.0", style: TextStyle(color: Colors.grey, fontSize: 10))),
          Center(child: Text("مستر نصر علي — معلم اللغة الإنجليزية", style: TextStyle(color: Colors.grey, fontSize: 10))),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold));

  Widget _statCard(String title, String value, Color color, IconData icon) => Expanded(child: Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _isDark ? color.withOpacity(0.15) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      Text(title, style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
    ]),
  ));

  Widget _debtAlert(Student s) => Container(
    margin: EdgeInsets.only(bottom: 6),
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(Icons.warning_amber, color: Colors.red, size: 18),
      SizedBox(width: 8),
      Text(s.name, style: TextStyle(fontWeight: FontWeight.bold)),
      Spacer(),
      Text("${s.balance.toStringAsFixed(0)} ج.م", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _honorCard(Student s, int rank) {
    final colors = [Colors.amber, Colors.grey, Colors.brown];
    final medals = ['🥇', '🥈', '🥉'];
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors[rank].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[rank].withOpacity(0.4)),
      ),
      child: Column(children: [
        Text(medals[rank], style: TextStyle(fontSize: 18)),
        SizedBox(height: 4),
        Text(s.name.split(' ').first, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text("${s.xp} XP", style: TextStyle(fontSize: 10, color: colors[rank])),
      ]),
    );
  }

  Widget _actionBtn(String title, IconData icon, Color color, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        decoration: BoxDecoration(
          color: _isDark ? Colors.white.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color, size: 20)),
          SizedBox(width: 14),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Spacer(),
          Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 13),
        ]),
      ),
    ),
  );
}
