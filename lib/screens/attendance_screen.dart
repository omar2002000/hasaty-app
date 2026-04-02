import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';

class AttendanceScreen extends StatefulWidget {
  final Student student;
  AttendanceScreen({required this.student});
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceRecord> records = [];
  List<Payment> payments = [];
  double percentage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final r = await DatabaseHelper.instance.getStudentAttendance(widget.student.id!);
    final p = await DatabaseHelper.instance.getStudentPayments(widget.student.id!);
    final pct = await DatabaseHelper.instance.getAttendancePercentage(widget.student.id!);
    setState(() { records = r; payments = p; percentage = pct; });
  }

  @override
  Widget build(BuildContext context) {
    final present = records.where((r) => r.present).length;
    final absent = records.where((r) => !r.present).length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("سجل ${widget.student.name}"),
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [Tab(text: "الحضور والغياب"), Tab(text: "سجل الدفعات")],
          ),
        ),
        body: Column(children: [
          // ملخص
          Container(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              _statBox("الحضور", "$present حصة", Colors.green),
              SizedBox(width: 8),
              _statBox("الغياب", "$absent حصة", Colors.red),
              SizedBox(width: 8),
              _statBox("نسبة الحضور", "${percentage.toStringAsFixed(0)}%",
                percentage >= 75 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red),
            ]),
          ),
          Expanded(
            child: TabBarView(children: [
              // تبويب الحضور
              records.isEmpty
                ? Center(child: Text("لا يوجد سجل حضور بعد", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (ctx, i) {
                      final r = records[i];
                      return ListTile(
                        leading: Icon(r.present ? Icons.check_circle : Icons.cancel, color: r.present ? Colors.green : Colors.red),
                        title: Text(r.present ? "حاضر" : "غائب", style: TextStyle(color: r.present ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                        subtitle: Text(r.groupName),
                        trailing: Text(r.date, style: TextStyle(color: Colors.grey, fontSize: 12)),
                      );
                    },
                  ),
              // تبويب الدفعات
              payments.isEmpty
                ? Center(child: Text("لا توجد دفعات مسجلة بعد", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (ctx, i) {
                      final p = payments[i];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.2), child: Icon(Icons.payments, color: Colors.green)),
                        title: Text("${p.amount.toStringAsFixed(0)} ج.م", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        subtitle: Text(p.note.isNotEmpty ? p.note : "دفعة"),
                        trailing: Text(p.date, style: TextStyle(fontSize: 11, color: Colors.grey)),
                      );
                    },
                  ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statBox(String title, String value, Color color) => Expanded(child: Container(
    padding: EdgeInsets.all(10),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      Text(title, style: TextStyle(fontSize: 11, color: Colors.grey)),
    ]),
  ));
}
