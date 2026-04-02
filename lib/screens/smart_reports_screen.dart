import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';

class SmartReportsScreen extends StatefulWidget {
  @override
  _SmartReportsScreenState createState() => _SmartReportsScreenState();
}

class _SmartReportsScreenState extends State<SmartReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  Map<String, dynamic> _report = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

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
        title: Text("التقارير الذكية"),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: "المالي"),
            Tab(text: "الالتزام"),
            Tab(text: "الغياب"),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [
              _financialTab(),
              _commitmentTab(),
              _absenceTab(),
            ]),
    );
  }

  // ===== تبويب المالي =====
  Widget _financialTab() {
    final income = _report['monthlyIncome'] ?? 0.0;
    final debt = _report['totalDebt'] ?? 0.0;
    final debtStudents = (_report['debtStudents'] as List<Student>?) ?? [];
    final paymentsCount = _report['monthlyPaymentsCount'] ?? 0;
    final now = DateTime.now();
    final months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle("${months[now.month]} ${now.year}", Icons.calendar_month, Colors.blue),
        SizedBox(height: 12),
        Row(children: [
          _bigCard("جمعت هذا الشهر", "${income.toStringAsFixed(0)} ج.م", Colors.green, Icons.trending_up),
          SizedBox(width: 10),
          _bigCard("ديون متراكمة", "${debt.toStringAsFixed(0)} ج.م", Colors.red, Icons.money_off),
        ]),
        SizedBox(height: 8),
        Row(children: [
          _bigCard("عدد الدفعات", "$paymentsCount دفعة", Colors.blue, Icons.receipt),
          SizedBox(width: 10),
          _bigCard("المديونون", "${debtStudents.length} طالب", Colors.orange, Icons.warning_amber),
        ]),

        if (debtStudents.isNotEmpty) ...[
          SizedBox(height: 20),
          _sectionTitle("الطلاب المديونون", Icons.warning_amber, Colors.red),
          SizedBox(height: 8),
          ...debtStudents.map((s) => _studentDebtTile(s)),
        ],
      ]),
    );
  }

  // ===== تبويب الالتزام =====
  Widget _commitmentTab() {
    final best = (_report['bestAttendance'] as List?) ?? [];
    final weekStar = _report['weekStar'] as Student?;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (weekStar != null) ...[
          _sectionTitle("نجم الأسبوع", Icons.star, Colors.amber),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.2), Colors.orange.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(children: [
              Text("⭐", style: TextStyle(fontSize: 40)),
              SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(weekStar.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${weekStar.xp} نقطة XP | ${weekStar.levelEmoji} ${weekStar.level}", style: TextStyle(color: Colors.orange)),
                Text(weekStar.groupName, style: TextStyle(color: Colors.grey, fontSize: 13)),
              ])),
            ]),
          ),
          SizedBox(height: 20),
        ],

        _sectionTitle("أفضل 3 طلاب التزاماً", Icons.emoji_events, Colors.green),
        SizedBox(height: 8),
        if (best.isEmpty)
          Center(child: Padding(padding: EdgeInsets.all(20), child: Text("لا توجد بيانات حضور بعد", style: TextStyle(color: Colors.grey))))
        else
          ...best.asMap().entries.map((e) {
            final student = e.value['student'] as Student;
            final pct = e.value['percentage'] as double;
            return _attendanceTile(student, pct, e.key);
          }),
      ]),
    );
  }

  // ===== تبويب الغياب =====
  Widget _absenceTab() {
    final absent = (_report['mostAbsent'] as List?) ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle("أكثر الطلاب غياباً", Icons.person_off, Colors.red),
        SizedBox(height: 8),
        if (absent.isEmpty)
          Center(child: Padding(padding: EdgeInsets.all(20), child: Text("لا توجد بيانات غياب بعد", style: TextStyle(color: Colors.grey))))
        else
          ...absent.asMap().entries.map((e) {
            final student = e.value['student'] as Student;
            final pct = e.value['percentage'] as double;
            final absencePct = 100 - pct;
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  child: Text("${e.key + 1}", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                title: Text(student.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student.groupName, style: TextStyle(fontSize: 12)),
                  SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: absencePct / 100,
                    backgroundColor: Colors.grey[200],
                    color: absencePct > 50 ? Colors.red : Colors.orange,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ]),
                trailing: Text("${absencePct.toStringAsFixed(0)}%\nغياب",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            );
          }),
      ]),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) => Row(children: [
    Icon(icon, color: color, size: 20),
    SizedBox(width: 8),
    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  ]);

  Widget _bigCard(String title, String value, Color color, IconData icon) => Expanded(child: Container(
    padding: EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
    ]),
  ));

  Widget _studentDebtTile(Student s) => Container(
    margin: EdgeInsets.only(bottom: 6),
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(Icons.warning_amber, color: Colors.red, size: 18),
      SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.name, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(s.groupName, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
      Text("${s.balance.abs().toStringAsFixed(0)} ج.م",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
    ]),
  );

  Widget _attendanceTile(Student s, double pct, int rank) {
    final medals = ['🥇', '🥈', '🥉'];
    final color = pct >= 80 ? Colors.green : pct >= 60 ? Colors.orange : Colors.red;
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(medals[rank], style: TextStyle(fontSize: 24)),
        title: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.groupName, style: TextStyle(fontSize: 12)),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ]),
        trailing: Text("${pct.toStringAsFixed(0)}%",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
