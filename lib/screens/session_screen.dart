import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../database_helper.dart';

class SessionScreen extends StatefulWidget {
  final Group group;
  SessionScreen({required this.group});
  @override
  _SessionScreenState createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  List<Student> students = [];
  Map<int, bool> attendance = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  _loadStudents() async {
    final all = await DatabaseHelper.instance.getStudents();
    setState(() {
      students = all.where((s) => s.groupName == widget.group.name).toList();
      for (var s in students) attendance[s.id!] = true;
    });
  }

  _finishSession() async {
    final now = DateTime.now();
    final date = '${now.day}/${now.month}/${now.year}';
    List<Student> absentStudents = [];

    for (var s in students) {
      final isPresent = attendance[s.id] == true;
      if (isPresent) {
        s.balance -= widget.group.price;
        s.xp += 10;
        await DatabaseHelper.instance.updateStudent(s);
      } else {
        absentStudents.add(s);
      }
      // تسجيل الحضور في قاعدة البيانات
      await DatabaseHelper.instance.addAttendance(AttendanceRecord(
        studentId: s.id!,
        studentName: s.name,
        groupName: widget.group.name,
        date: date,
        present: isPresent,
      ));
    }

    // إذا في غائبين — اسأل عن إرسال تذكير
    if (absentStudents.isNotEmpty && mounted) {
      Navigator.pop(context);
      _showAbsenceReminder(absentStudents);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم إنهاء الحصة بنجاح! ✅"), backgroundColor: Colors.green),
      );
    }
  }

  _showAbsenceReminder(List<Student> absent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [Icon(Icons.notifications_active, color: Colors.orange), SizedBox(width: 8), Text("الطلاب الغائبون")]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("غاب ${absent.length} طالب عن الحصة — هل تريد إرسال تذكير واتساب لهم؟"),
            SizedBox(height: 12),
            ...absent.map((s) => Padding(
              padding: EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [Icon(Icons.person_off, size: 16, color: Colors.red), SizedBox(width: 6), Text(s.name)]),
            )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("تجاهل")),
          ElevatedButton.icon(
            icon: Icon(Icons.send, color: Colors.white),
            label: Text("إرسال للكل", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              _sendAbsenceMessages(absent);
            },
          ),
        ],
      ),
    );
  }

  _sendAbsenceMessages(List<Student> absent) async {
    for (var s in absent) {
      String p = s.phone.startsWith('0') ? s.phone.substring(1) : s.phone;
      final msg = Uri.encodeComponent('أهلاً يا ${s.name}،\nغبت عن حصة اليوم في مجموعة ${widget.group.name}.\nيرجى الحضور في المرة القادمة.\nمعلمك: مستر نصر علي');
      var url = "https://wa.me/20$p?text=$msg";
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final present = attendance.values.where((v) => v).length;
    final absent = attendance.values.where((v) => !v).length;

    return Scaffold(
      appBar: AppBar(
        title: Text("حصة: ${widget.group.name}"),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // ملخص الحضور
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Color(0xFF1E3A8A).withOpacity(0.05),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _summaryItem("الكل", students.length.toString(), Colors.blue),
            _summaryItem("حاضر", present.toString(), Colors.green),
            _summaryItem("غائب", absent.toString(), Colors.red),
            _summaryItem("سعر الحصة", "${widget.group.price.toStringAsFixed(0)} ج", Colors.orange),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (ctx, i) {
              final s = students[i];
              final isPresent = attendance[s.id]!;
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("رصيده: ${s.balance.toStringAsFixed(0)} ج.م | XP: ${s.xp}"),
                  value: isPresent,
                  activeColor: Colors.green,
                  onChanged: (v) => setState(() => attendance[s.id!] = v),
                  secondary: CircleAvatar(
                    backgroundColor: isPresent ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    child: Icon(isPresent ? Icons.check : Icons.close, color: isPresent ? Colors.green : Colors.red),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: ElevatedButton.icon(
            icon: Icon(Icons.done_all, color: Colors.white),
            label: Text("إنهاء الحصة وخصم الرصيد (${present} حاضر)", style: TextStyle(color: Colors.white, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 56),
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: students.isEmpty ? null : _finishSession,
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
  ]);
}
