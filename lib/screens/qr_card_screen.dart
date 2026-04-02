import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models.dart';

class QrCardScreen extends StatelessWidget {
  final Student student;
  QrCardScreen({required this.student});

  @override
  Widget build(BuildContext context) {
    // بيانات QR: id:groupName
    final qrData = 'hasaty:${student.id}:${student.groupName}';

    return Scaffold(
      backgroundColor: Color(0xFF1E3A8A),
      appBar: AppBar(
        title: Text("كارت الطالب"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الكارت
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: Column(children: [
                  // رأس الكارت
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(children: [
                      Text("حصتي", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text("مستر نصر علي — معلم اللغة الإنجليزية", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),

                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(children: [
                      // صورة رمزية
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Color(0xFF1E3A8A).withOpacity(0.1),
                        child: Text(
                          student.name.isNotEmpty ? student.name[0] : '?',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                      SizedBox(height: 12),

                      // اسم الطالب
                      Text(student.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      SizedBox(height: 4),
                      Text(student.groupName, style: TextStyle(color: Colors.grey, fontSize: 14)),

                      // المستوى
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _levelColor(student.level).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _levelColor(student.level).withOpacity(0.4)),
                        ),
                        child: Text(
                          '${student.levelEmoji} ${student.level} — ${student.xp} XP',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _levelColor(student.level)),
                        ),
                      ),

                      SizedBox(height: 20),
                      Divider(),
                      SizedBox(height: 16),

                      // QR Code
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                      ),

                      SizedBox(height: 12),
                      Text("امسح هذا الكود للحضور", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      SizedBox(height: 8),
                      Text("ID: ${student.id}", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    ]),
                  ),
                ]),
              ),

              SizedBox(height: 24),
              Text("اعرض هذا الكارت للمدرس عند بداية الحصة",
                style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'نجم': return Colors.amber;
      case 'متقدم': return Colors.orange;
      case 'متوسط': return Colors.blue;
      default: return Colors.green;
    }
  }
}
