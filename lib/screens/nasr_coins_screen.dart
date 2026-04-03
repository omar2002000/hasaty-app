import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class NasrCoinsScreen extends StatefulWidget {
  const NasrCoinsScreen();
  @override
  _NasrCoinsScreenState createState() => _NasrCoinsScreenState();
}

class _NasrCoinsScreenState extends State<NasrCoinsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Student> _students = [];
  bool _loading = true;

  final _rewards = [
    {'title': 'خصم 10% على المذكرة', 'coins': 50,  'emoji': '📚', 'color': AppTheme.primary},
    {'title': 'خصم حصة واحدة',       'coins': 100, 'emoji': '🎓', 'color': AppTheme.success},
    {'title': 'بطاقة شرف الأسبوع',   'coins': 30,  'emoji': '🏆', 'color': AppTheme.warning},
    {'title': 'جلسة مراجعة مجانية', 'coins': 150, 'emoji': '⭐', 'color': AppTheme.purple},
    {'title': 'هدية مفاجأة',         'coins': 200, 'emoji': '🎁', 'color': AppTheme.accent},
  ];

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getStudents();
    if (!mounted) return;
    setState(() { _students = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Row(children: [const Text('عملة نصر'), const SizedBox(width: 6), const Text('🪙', style: TextStyle(fontSize: 18))]),
      bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
        tabs: const [Tab(text: 'الأرصدة'), Tab(text: 'متجر المكافآت'), Tab(text: 'إدارة')])),
    body: _loading ? const LoadingWidget() : TabBarView(controller: _tab, children: [_balances(), _store(), _manage()]),
  );

  Widget _balances() => FutureBuilder<List<Map<String, dynamic>>>(
    future: _coinsData(),
    builder: (ctx, snap) => snap.hasData
        ? ListView.builder(padding: const EdgeInsets.all(14), itemCount: snap.data!.length, itemBuilder: (ctx, i) {
            final s = snap.data![i]['student'] as Student; final c = snap.data![i]['coins'] as int; final isDark = Theme.of(context).brightness == Brightness.dark;
            const medals = ['🥇', '🥈', '🥉'];
            return Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard, borderRadius: BorderRadius.circular(11), border: Border.all(color: i < 3 ? AppTheme.warning.withOpacity(0.3) : const Color(0xFFE2E8F0))), child: Row(children: [
              Text(i < 3 ? medals[i] : '${i+1}', style: TextStyle(fontSize: i < 3 ? 20 : 13, fontWeight: FontWeight.bold)), const SizedBox(width: 8),
              Container(width: 34, height: 34, decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Center(child: Text(s.name[0], style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 9),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(s.groupName, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary))])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Row(children: [const Text('🪙', style: TextStyle(fontSize: 13)), const SizedBox(width: 4), Text('$c', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning, fontSize: 13))])),
            ]));
          })
        : const LoadingWidget(),
  );

  Widget _store() => ListView.builder(padding: const EdgeInsets.all(14), itemCount: _rewards.length, itemBuilder: (ctx, i) {
    final r = _rewards[i]; final c = r['color'] as Color;
    return Container(margin: const EdgeInsets.only(bottom: 11), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(15), border: Border.all(color: c.withOpacity(0.2))), child: Row(children: [
      Text(r['emoji'] as String, style: const TextStyle(fontSize: 28)), const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 3), Row(children: [const Text('🪙', style: TextStyle(fontSize: 13)), const SizedBox(width: 4), Text('${r['coins']} عملة', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold))])])),
      ElevatedButton(onPressed: () => _redeemDialog(r), style: ElevatedButton.styleFrom(backgroundColor: c, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7)), child: const Text('صرف', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
    ]));
  });

  Widget _manage() => ListView.builder(padding: const EdgeInsets.all(14), itemCount: _students.length, itemBuilder: (ctx, i) {
    final s = _students[i]; final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard, borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Center(child: Text(s.name[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 9),
      Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.success), onPressed: () => _awardDialog(s), tooltip: 'منح'),
      IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger), onPressed: () => _spendDialog(s), tooltip: 'خصم'),
    ]));
  });

  Future<List<Map<String, dynamic>>> _coinsData() async {
    final result = <Map<String, dynamic>>[];
    for (final s in _students) { final c = await DatabaseHelper.instance.getStudentCoins(s.id!); result.add({'student': s, 'coins': c}); }
    result.sort((a, b) => (b['coins'] as int).compareTo(a['coins'] as int));
    return result;
  }

  void _redeemDialog(Map<String, dynamic> r) {
    Student? sel;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('صرف: ${r['title']}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('اختر الطالب لصرف ${r['coins']} عملة:'),
        const SizedBox(height: 10),
        DropdownButtonFormField<Student>(decoration: const InputDecoration(labelText: 'الطالب'), items: _students.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(), onChanged: (v) => setS(() => sel = v)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(
        onPressed: sel == null ? null : () async { await DatabaseHelper.instance.spendCoins(sel!.id!, sel!.name, r['coins'] as int, r['title'] as String); if (!mounted) return; Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم صرف ${r['coins']} عملة لـ ${sel!.name}'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating)); setState(() {}); },
        child: const Text('تأكيد'),
      )],
    )));
  }

  void _awardDialog(Student s) { int a = 10; String reason = ''; showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: Text('منح عملات — ${s.name}'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(decoration: const InputDecoration(labelText: 'عدد العملات'), keyboardType: TextInputType.number, onChanged: (v) => a = int.tryParse(v) ?? 10), const SizedBox(height: 9), TextField(decoration: const InputDecoration(labelText: 'السبب'), onChanged: (v) => reason = v)]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(onPressed: () async { await DatabaseHelper.instance.awardCoins(s.id!, s.name, a, reason.isEmpty ? 'منحة يدوية' : reason); if (!mounted) return; Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🪙 منحت $a عملة لـ ${s.name}'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating)); setState(() {}); }, child: const Text('منح'))]))); }

  void _spendDialog(Student s) { int a = 10; String reason = ''; showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: Text('خصم عملات — ${s.name}'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(decoration: const InputDecoration(labelText: 'عدد العملات'), keyboardType: TextInputType.number, onChanged: (v) => a = int.tryParse(v) ?? 10), const SizedBox(height: 9), TextField(decoration: const InputDecoration(labelText: 'السبب'), onChanged: (v) => reason = v)]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(onPressed: () async { await DatabaseHelper.instance.spendCoins(s.id!, s.name, a, reason.isEmpty ? 'صرف يدوي' : reason); if (!mounted) return; Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🪙 خصمت $a عملة من ${s.name}'), backgroundColor: AppTheme.warning, behavior: SnackBarBehavior.floating)); setState(() {}); }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('خصم', style: TextStyle(color: Colors.white)))])); }
}
