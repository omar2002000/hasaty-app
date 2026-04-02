import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';

class GamificationScreen extends StatefulWidget {
  @override
  _GamificationScreenState createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  List<Student> students = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  _load() async {
    final data = await DatabaseHelper.instance.getStudents();
    setState(() { students = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("نظام التحفيز والمستويات"),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // نجم الأسبوع
                if (students.isNotEmpty) _weekStarCard(students.first),
                SizedBox(height: 20),

                // شرح نظام النقاط
                _xpExplainer(),
                SizedBox(height: 20),

                // قائمة الطلاب بمستوياتهم
                Text("ترتيب الطلاب", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ...students.asMap().entries.map((e) => _studentLevelCard(e.value, e.key)),
              ]),
            ),
    );
  }

  Widget _weekStarCard(Student s) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Color(0xFF1E3A8A),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(children: [
      Text("⭐", style: TextStyle(fontSize: 48)),
      SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("نجم الأسبوع", style: TextStyle(color: Colors.white70, fontSize: 13)),
        Text(s.name, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text("${s.xp} نقطة XP — ${s.levelEmoji} ${s.level}", style: TextStyle(color: Colors.white70)),
      ])),
    ]),
  );

  Widget _xpExplainer() => Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.amber.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.amber.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.info_outline, color: Colors.amber), SizedBox(width: 8), Text("كيف تُكسب النقاط؟", style: TextStyle(fontWeight: FontWeight.bold))]),
      SizedBox(height: 10),
      _xpRow("🟢", "الحضور", "+10 نقطة لكل حصة"),
      _xpRow("💰", "الدفع المنتظم", "+5 نقاط عند كل دفعة"),
      SizedBox(height: 10),
      Divider(),
      SizedBox(height: 6),
      Text("المستويات:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _levelBadge("🌱", "مبتدئ", "0-49"),
        _levelBadge("📈", "متوسط", "50-199"),
        _levelBadge("🔥", "متقدم", "200-499"),
        _levelBadge("⭐", "نجم", "500+"),
      ]),
    ]),
  );

  Widget _xpRow(String emoji, String action, String points) => Padding(
    padding: EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(emoji, style: TextStyle(fontSize: 16)),
      SizedBox(width: 8),
      Text(action, style: TextStyle(fontSize: 13)),
      Spacer(),
      Text(points, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
    ]),
  );

  Widget _levelBadge(String emoji, String label, String range) => Column(children: [
    Text(emoji, style: TextStyle(fontSize: 22)),
    Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    Text(range, style: TextStyle(fontSize: 9, color: Colors.grey)),
  ]);

  Widget _studentLevelCard(Student s, int rank) {
    final levelColor = _getLevelColor(s.level);
    final progress = s.xp / s.nextLevelXp;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(children: [
          // الترتيب
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: levelColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: Text("${rank + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: levelColor))),
          ),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: levelColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text('${s.levelEmoji} ${s.level}', style: TextStyle(fontSize: 10, color: levelColor, fontWeight: FontWeight.bold)),
              ),
            ]),
            SizedBox(height: 4),
            Text(s.groupName, style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 6),
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  color: levelColor,
                  minHeight: 7,
                ),
              )),
              SizedBox(width: 8),
              Text("${s.xp}/${s.nextLevelXp}", style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ])),
          SizedBox(width: 12),
          Column(children: [
            Text("${s.xp}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: levelColor)),
            Text("XP", style: TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'نجم': return Colors.amber;
      case 'متقدم': return Colors.orange;
      case 'متوسط': return Colors.blue;
      default: return Colors.green;
    }
  }
}
