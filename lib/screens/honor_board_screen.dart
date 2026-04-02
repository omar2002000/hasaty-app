import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';

class HonorBoardScreen extends StatefulWidget {
  @override
  _HonorBoardScreenState createState() => _HonorBoardScreenState();
}

class _HonorBoardScreenState extends State<HonorBoardScreen> {
  List<Student> students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final data = await DatabaseHelper.instance.getStudents();
    setState(() => students = data..sort((a, b) => b.xp.compareTo(a.xp)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("لوحة شرف الطلاب"),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // أفضل 3 طلاب
        if (students.length >= 3)
          Container(
            padding: EdgeInsets.all(20),
            color: Color(0xFF1E3A8A).withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _podium(students[1], 2, 70),
                _podium(students[0], 1, 100),
                _podium(students[2], 3, 50),
              ],
            ),
          ),
        Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (ctx, i) {
              final s = students[i];
              final medals = ['🥇', '🥈', '🥉'];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: i < 3 ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  child: Text(i < 3 ? medals[i] : "${i+1}", style: TextStyle(fontSize: i < 3 ? 18 : 14)),
                ),
                title: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(s.groupName),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("${s.xp}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                  Text("نقطة XP", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _podium(Student s, int rank, double height) {
    final colors = {1: Colors.amber, 2: Colors.grey, 3: Colors.brown};
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(medals[rank]!, style: TextStyle(fontSize: 24)),
      SizedBox(height: 4),
      Text(s.name.split(' ').first, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
      Text("${s.xp} XP", style: TextStyle(color: colors[rank], fontSize: 12)),
      SizedBox(height: 6),
      Container(
        width: 70,
        height: height,
        decoration: BoxDecoration(
          color: colors[rank]!.withOpacity(0.3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(color: colors[rank]!.withOpacity(0.5)),
        ),
        child: Center(child: Text("$rank", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors[rank]))),
      ),
    ]);
  }
}
