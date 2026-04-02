import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class RiskDetectionScreen extends StatefulWidget {
  @override
  _RiskDetectionScreenState createState() => _RiskDetectionScreenState();
}

class _RiskDetectionScreenState extends State<RiskDetectionScreen> {
  List<Map<String, dynamic>> _riskStudents = [];
  List<Map<String, dynamic>> _heatmapData = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  _load() async {
    final students = await DatabaseHelper.instance.getStudents();
    List<Map<String, dynamic>> risks = [];
    List<Map<String, dynamic>> heatmap = [];

    for (final s in students) {
      final pct = await DatabaseHelper.instance.getAttendancePercentage(s.id!);
      final risk = s.riskLevel(pct);
      risks.add({'student': s, 'risk': risk, 'attendance': pct});
      heatmap.add({'student': s, 'debt': s.balance.abs(), 'attendance': pct});
    }

    risks.sort((a, b) {
      const order = {'خطر': 0, 'متأخر': 1, 'ملتزم': 2};
      return (order[a['risk']] ?? 2).compareTo(order[b['risk']] ?? 2);
    });
    heatmap.sort((a, b) => (b['debt'] as double).compareTo(a['debt'] as double));

    setState(() { _riskStudents = risks; _heatmapData = heatmap; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final danger = _riskStudents.where((r) => r['risk'] == 'خطر').length;
    final late = _riskStudents.where((r) => r['risk'] == 'متأخر').length;
    final ok = _riskStudents.where((r) => r['risk'] == 'ملتزم').length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('كشف المخاطر'),
          bottom: TabBar(
            labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
            tabs: [Tab(text: 'تصنيف الطلاب'), Tab(text: 'خريطة الديون')],
          ),
        ),
        body: _loading ? LoadingWidget() : Column(children: [
          // ملخص
          Container(
            padding: EdgeInsets.all(16),
            color: AppTheme.primary.withOpacity(0.04),
            child: Row(children: [
              _riskSummary('خطر', danger, AppTheme.danger, Icons.warning),
              _riskSummary('متأخر', late, AppTheme.warning, Icons.access_time),
              _riskSummary('ملتزم', ok, AppTheme.success, Icons.check_circle),
            ]),
          ),
          Expanded(child: TabBarView(children: [
            _riskTab(),
            _heatmapTab(),
          ])),
        ]),
      ),
    );
  }

  Widget _riskSummary(String label, int count, Color color, IconData icon) => Expanded(child: Container(
    margin: EdgeInsets.symmetric(horizontal: 4),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      SizedBox(height: 4),
      Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
      Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ]),
  ));

  Widget _riskTab() => _riskStudents.isEmpty
    ? EmptyState(icon: Icons.security, title: 'لا توجد بيانات', subtitle: 'أضف طلاباً وسجّل الحضور لرؤية التحليل')
    : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _riskStudents.length,
        itemBuilder: (ctx, i) {
          final s = _riskStudents[i]['student'] as Student;
          final risk = _riskStudents[i]['risk'] as String;
          final pct = _riskStudents[i]['attendance'] as double;
          final riskColor = risk == 'خطر' ? AppTheme.danger : risk == 'متأخر' ? AppTheme.warning : AppTheme.success;

          return Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: riskColor.withOpacity(0.2)),
            ),
            child: Column(children: [
              Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: riskColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(s.name[0], style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 16)))),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(s.groupName, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ])),
                StatusBadge(label: risk, color: riskColor, icon: risk == 'خطر' ? Icons.warning : risk == 'متأخر' ? Icons.access_time : Icons.check),
              ]),
              SizedBox(height: 10),
              Row(children: [
                Expanded(child: _miniInfo('الحضور', '${pct.toStringAsFixed(0)}%', pct >= 75 ? AppTheme.success : AppTheme.danger)),
                SizedBox(width: 8),
                Expanded(child: _miniInfo('الرصيد', '${s.balance.toStringAsFixed(0)} ج', s.balance >= 0 ? AppTheme.success : AppTheme.danger)),
                SizedBox(width: 8),
                Expanded(child: _miniInfo('XP', '${s.xp}', AppTheme.warning)),
              ]),
              if (risk == 'خطر') ...[
                SizedBox(height: 10),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  icon: Icon(Icons.chat, size: 14, color: Colors.white),
                  label: Text('إرسال تحذير واتساب', style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () => _sendWarning(s),
                )),
              ],
            ]),
          );
        },
      );

  Widget _heatmapTab() {
    if (_heatmapData.isEmpty) return EmptyState(icon: Icons.thermostat, title: 'لا توجد بيانات', subtitle: 'أضف طلاباً لرؤية خريطة الديون');
    final maxDebt = _heatmapData.fold(0.0, (m, d) => (d['debt'] as double) > m ? d['debt'] as double : m);

    return Column(children: [
      // مفتاح الألوان
      Padding(
        padding: EdgeInsets.all(16),
        child: Row(children: [
          Text('الديون: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Expanded(child: Container(height: 10, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.success, AppTheme.warning, AppTheme.danger]),
            borderRadius: BorderRadius.circular(5),
          ))),
          SizedBox(width: 8),
          Text('عالي', style: TextStyle(fontSize: 11, color: AppTheme.danger)),
        ]),
      ),
      Expanded(child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _heatmapData.length,
        itemBuilder: (ctx, i) {
          final s = _heatmapData[i]['student'] as Student;
          final debt = _heatmapData[i]['debt'] as double;
          final pct = _heatmapData[i]['attendance'] as double;
          final ratio = maxDebt > 0 ? debt / maxDebt : 0.0;
          final heatColor = Color.lerp(AppTheme.success, AppTheme.danger, ratio)!;

          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: heatColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: heatColor, width: 4)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(s.groupName, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(s.balance < 0 ? '${debt.toStringAsFixed(0)} ج دين' : 'لا دين', style: TextStyle(color: heatColor, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('حضور ${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ]),
            ]),
          );
        },
      )),
    ]);
  }

  Widget _miniInfo(String label, String value, Color color) => Container(
    padding: EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
    ]),
  );

  _sendWarning(Student s) async {
    final p = s.phone.startsWith('0') ? s.phone.substring(1) : s.phone;
    final msg = Uri.encodeComponent('أهلاً يا ${s.name}،\nنُنبّهك بأن غيابك وتراكم الديون قد يؤثر على مستواك.\nيرجى التواصل معنا لترتيب الأمور.\nمعلمك: مستر نصر علي');
    final url = "https://wa.me/20$p?text=$msg";
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
