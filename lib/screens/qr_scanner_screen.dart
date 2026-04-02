import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../database_helper.dart';
import '../models.dart';

class QrScannerScreen extends StatefulWidget {
  final Group group;
  QrScannerScreen({required this.group});
  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _processing = false;
  String _lastMessage = '';
  bool _lastSuccess = false;
  Student? _lastStudent;
  List<String> _attendedNames = [];
  int _attendedCount = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;

    // تحقق أن الكود من تطبيق حصتي
    if (!raw.startsWith('hasaty:')) {
      _showResult(false, 'كود غير صحيح — ليس من تطبيق حصتي', null);
      return;
    }

    setState(() => _processing = true);

    try {
      final parts = raw.split(':');
      if (parts.length < 3) {
        _showResult(false, 'كود تالف — اطلب من الطالب إعادة توليده', null);
        return;
      }

      final studentId = int.tryParse(parts[1]);
      if (studentId == null) {
        _showResult(false, 'كود غير صالح', null);
        return;
      }

      final result = await DatabaseHelper.instance.markAttendanceByQR(
          studentId, widget.group.name, widget.group.price);

      if (result['success'] == true) {
        final student = result['student'] as Student;
        setState(() {
          _attendedCount++;
          if (!_attendedNames.contains(student.name)) {
            _attendedNames.add(student.name);
          }
        });
        _showResult(true, result['message'], student);
      } else {
        _showResult(false, result['message'], result['student']);
      }
    } catch (e) {
      _showResult(false, 'حدث خطأ — حاول مجدداً', null);
    }
  }

  void _showResult(bool success, String message, Student? student) {
    setState(() {
      _lastSuccess = success;
      _lastMessage = message;
      _lastStudent = student;
    });

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) setState(() { _processing = false; _lastMessage = ''; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("وضع التحضير الذكي", style: TextStyle(fontSize: 16)),
          Text("مجموعة: ${widget.group.name}", style: TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          Center(child: Padding(
            padding: EdgeInsets.only(left: 16),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$_attendedCount', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              Text('حاضر', style: TextStyle(fontSize: 10, color: Colors.white70)),
            ]),
          )),
        ],
      ),
      body: Stack(children: [
        // الكاميرا
        MobileScanner(controller: controller, onDetect: _onDetect),

        // إطار التصويب
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(children: [
              // زوايا الإطار
              _corner(0, 0, true, true),
              _corner(0, null, true, false),
              _corner(null, 0, false, true),
              _corner(null, null, false, false),
            ]),
          ),
        ),

        // تعليمات
        Positioned(
          bottom: 120,
          left: 0, right: 0,
          child: Text(
            'وجّه الكاميرا نحو كارت QR الطالب',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),

        // نتيجة المسح
        if (_lastMessage.isNotEmpty)
          Positioned(
            bottom: 30,
            left: 20, right: 20,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lastSuccess ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                if (_lastStudent != null)
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      _lastStudent!.name.isNotEmpty ? _lastStudent!.name[0] : '?',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_lastMessage, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  if (_lastStudent != null && _lastSuccess)
                    Text('XP: ${_lastStudent!.xp} | رصيده: ${_lastStudent!.balance.toStringAsFixed(0)} ج',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
                Icon(_lastSuccess ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 28),
              ]),
            ),
          ),

        // قائمة الحضور في الأعلى
        if (_attendedNames.isNotEmpty)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'حضر: ${_attendedNames.join(' • ')}',
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ]),
    );
  }

  Widget _corner(double? top, double? bottom, bool left, bool right) {
    return Positioned(
      top: top != null ? top + 8 : null,
      bottom: bottom != null ? bottom + 8 : null,
      left: left ? 8 : null,
      right: right ? null : 8,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? BorderSide(color: Colors.greenAccent, width: 3) : BorderSide.none,
            bottom: bottom != null ? BorderSide(color: Colors.greenAccent, width: 3) : BorderSide.none,
            left: left ? BorderSide(color: Colors.greenAccent, width: 3) : BorderSide.none,
            right: !left ? BorderSide(color: Colors.greenAccent, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
