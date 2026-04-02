// ===== financial_report_screen.dart =====
// احفظ هذا الكود في lib/screens/financial_report_screen.dart

import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';

class FinancialReportScreen extends StatefulWidget {
  @override
  _FinancialReportScreenState createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  List<Payment> payments = [];
  double totalIncome = 0;
  double totalDebt = 0;
  int debtCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final p = await DatabaseHelper.instance.getAllPayments();
    final students = await DatabaseHelper.instance.getStudents();
    final now = DateTime.now();
    final month = '/${now.month}/${now.year}';
    final monthly = p.where((x) => x.date.endsWith(month)).toList();
    final debts = students.where((s) => s.balance < 0).toList();
    setState(() {
      payments = monthly;
      totalIncome = monthly.fold(0, (sum, x) => sum + x.amount);
      totalDebt = debts.fold(0, (sum, s) => sum + s.balance.abs());
      debtCount = debts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['', 'يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return Scaffold(
      appBar: AppBar(title: Text("التقرير المالي — ${months[now.month]} ${now.year}"), backgroundColor: Color(0xFF1E3A8A), foregroundColor: Colors.white),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            _card("جمعت هذا الشهر", "${totalIncome.toStringAsFixed(0)} ج", Colors.green),
            SizedBox(width: 10),
            _card("ديون متراكمة", "${totalDebt.toStringAsFixed(0)} ج", Colors.red),
            SizedBox(width: 10),
            _card("عدد المديونين", "$debtCount طالب", Colors.orange),
          ]),
        ),
        Divider(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [Icon(Icons.history, size: 18, color: Colors.grey), SizedBox(width: 6), Text("سجل المدفوعات هذا الشهر", style: TextStyle(fontWeight: FontWeight.bold))]),
        ),
        Expanded(
          child: payments.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox, size: 48, color: Colors.grey), SizedBox(height: 8), Text("لا توجد مدفوعات هذا الشهر", style: TextStyle(color: Colors.grey))]))
            : ListView.builder(
                itemCount: payments.length,
                itemBuilder: (ctx, i) {
                  final p = payments[i];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.2), child: Icon(Icons.payments, color: Colors.green)),
                    title: Text(p.studentName, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(p.note.isNotEmpty ? p.note : "دفعة"),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("${p.amount.toStringAsFixed(0)} ج", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                      Text(p.date, style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ]),
                  );
                },
              ),
        ),
      ]),
    );
  }

  Widget _card(String title, String value, Color color) => Expanded(child: Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
    child: Column(children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13), textAlign: TextAlign.center),
      SizedBox(height: 4),
      Text(title, style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
    ]),
  ));
}
