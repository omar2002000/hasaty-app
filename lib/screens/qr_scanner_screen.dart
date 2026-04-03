import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

// ===================== كارت QR الطالب =====================
class QrCardScreen extends StatelessWidget {
  final Student student;
  const QrCardScreen({required this.student});

  Color _lc() {
    switch (student.level) { case 'نجم': return AppTheme.warning; case 'متقدم': return AppTheme.purple; case 'متوسط': return AppTheme.primaryLight; default: return AppTheme.success; }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = 'hasaty:${student.id}:${student.groupName}';
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(title: const Text('كارت الطالب'), backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0),
      body: Center(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              Container(
                width: double.infinity, padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: const Column(children: [
                  Text('حصتي', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('مستر نصر علي — معلم اللغة الإنجليزية', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ]),
              ),
              Padding(padding: const EdgeInsets.all(22), child: Column(children: [
                Container(width: 64, height: 64, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                  child: Center(child: Text(student.name[0], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary)))),
                const SizedBox(height: 10),
                Text(student.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(student.groupName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: _lc().withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text('${student.levelEmoji} ${student.level} — ${student.xp} XP', style: TextStyle(fontWeight: FontWeight.bold, color: _lc())),
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 14),
                QrImageView(data: qrData, version: QrVersions.auto, size: 180, backgroundColor: Colors.white),
                const SizedBox(height: 10),
                const Text('امسح هذا الكود للحضور', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text('ID: ${student.id}', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
              ])),
            ]),
          ),
          const SizedBox(height: 18),
          const Text('اعرض هذا الكارت للمدرس عند بداية الحصة', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
        ]),
      )),
    );
  }
}

// ===================== ماسح QR للتحضير =====================
class QrScannerScreen extends StatefulWidget {
  final Group group;
  const QrScannerScreen({required this.group});
  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _processing = false;
  String _msg = '';
  bool _ok = false;
  Student? _lastStudent;
  int _count = 0;
  final List<String> _names = [];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || !raw.startsWith('hasaty:')) { _show(false, 'كود غير صحيح', null); return; }
    setState(() => _processing = true);
    try {
      final parts = raw.split(':');
      if (parts.length < 3) { _show(false, 'كود تالف', null); return; }
      final id = int.tryParse(parts[1]);
      if (id == null) { _show(false, 'كود غير صالح', null); return; }
      final result = await DatabaseHelper.instance.markAttendanceByQR(id, widget.group.name, widget.group.monthlyPrice);
      if (result['success'] == true) {
        final s = result['student'] as Student;
        setState(() { _count++; if (!_names.contains(s.name)) _names.add(s.name); });
        _show(true, result['message'] as String, s);
      } else {
        _show(false, result['message'] as String, result['student'] as Student?);
      }
    } catch (_) { _show(false, 'حدث خطأ — حاول مجدداً', null); }
  }

  void _show(bool ok, String msg, Student? s) {
    setState(() { _ok = ok; _msg = msg; _lastStudent = s; });
    Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() { _processing = false; _msg = ''; }); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('وضع التحضير الذكي', style: TextStyle(fontSize: 15)),
          Text('مجموعة: ${widget.group.name}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [Center(child: Padding(padding: const EdgeInsets.only(left: 16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$_count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          const Text('حاضر', style: TextStyle(fontSize: 9, color: Colors.white70)),
        ])))],
      ),
      body: Stack(children: [
        MobileScanner(controller: _ctrl, onDetect: _onDetect),
        Center(child: Container(
          width: 250, height: 250,
          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(14)),
        )),
        Positioned(bottom: 100, left: 0, right: 0, child: const Text('وجّه الكاميرا نحو كارت QR الطالب', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13))),
        if (_msg.isNotEmpty)
          Positioned(bottom: 20, left: 16, right: 16, child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _ok ? AppTheme.success : AppTheme.danger, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              if (_lastStudent != null) CircleAvatar(backgroundColor: Colors.white.withOpacity(0.2), child: Text(_lastStudent!.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                if (_lastStudent != null && _ok) Text('XP: ${_lastStudent!.xp} | رصيده: ${_lastStudent!.balance.toStringAsFixed(0)} ج', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ])),
              Icon(_ok ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 24),
            ]),
          )),
        if (_names.isNotEmpty)
          Positioned(top: 0, left: 0, right: 0, child: Container(
            color: Colors.black54, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text('حضر: ${_names.join(' • ')}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          )),
      ]),
    );
  }
}
