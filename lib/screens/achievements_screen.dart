import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';

class AchievementsScreen extends StatefulWidget {
  final Student student;
  AchievementsScreen({required this.student});
  @override
  _AchievementsScreenState createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<String> earned = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  _load() async {
    final a = await DatabaseHelper.instance.getStudentAchievements(widget.student.id!);
    setState(() { earned = a; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إنجازات ${widget.student.name}"),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(children: [
                // ملخص الطالب
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E3A8A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFF1E3A8A).withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: Color(0xFF1E3A8A).withOpacity(0.2),
                      radius: 28,
                      child: Text(widget.student.levelEmoji, style: TextStyle(fontSize: 24)),
                    ),
                    SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.student.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("${widget.student.levelEmoji} ${widget.student.level} — ${widget.student.xp} XP",
                          style: TextStyle(color: Color(0xFF1E3A8A))),
                    ])),
                    Text("${earned.length}/${Achievements.all.length}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  ]),
                ),
                SizedBox(height: 20),
                Text("سجل الإنجازات", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ...Achievements.all.map((a) {
                  final isEarned = earned.contains(a.id);
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isEarned ? Colors.amber.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isEarned ? Colors.amber.withOpacity(0.4) : Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Text(a.emoji, style: TextStyle(fontSize: 28, color: isEarned ? null : null, opacity: isEarned ? 1.0 : 0.3)),
                      SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.title, style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isEarned ? Colors.black87 : Colors.grey,
                        )),
                        Text(a.description, style: TextStyle(fontSize: 12, color: isEarned ? Colors.grey[700] : Colors.grey)),
                      ])),
                      if (isEarned)
                        Icon(Icons.check_circle, color: Colors.amber, size: 22)
                      else
                        Icon(Icons.lock_outline, color: Colors.grey[300], size: 22),
                    ]),
                  );
                }),
              ]),
            ),
    );
  }
}
