import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen();
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Subscription> _subs = [];
  bool _loading = true;
  late int _month, _year;
  final _months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _tab.addListener(() => setState(() {})); final n = DateTime.now(); _month = n.month; _year = n.year; _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DatabaseHelper.instance.getSubscriptions(month: _month, year: _year);
    if (!mounted) return;
    setState(() { _subs = data; _loading = false; });
  }

  List<Subscription> get _filtered { switch (_tab.index) { case 1: return _subs.where((s) => s.status == 'unpaid').toList(); case 2: return _subs.where((s) => s.status == 'partial').toList(); default: return _subs; } }
  double get _expected => _subs.fold(0.0, (s, x) => s + x.amount);
  double get _paid    => _subs.fold(0.0, (s, x) => s + x.paidAmount);
  double get _rate    => _expected > 0 ? _paid / _expected * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراكات الشهرية'),
        actions: [TextButton.icon(icon: const Icon(Icons.calendar_month, color: Colors.white, size: 15), label: Text('${_months[_month]} $_year', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onPressed: _pickMonth)],
        bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
          tabs: [Tab(text: 'الكل (${_subs.length})'), const Tab(text: 'غير مدفوع'), const Tab(text: 'جزئي')]),
      ),
      body: Column(children: [
        if (!_loading) _summaryBar(isDark),
        Expanded(child: _loading ? const LoadingWidget() : _filtered.isEmpty
            ? EmptyState(icon: Icons.receipt_long, title: 'لا توجد اشتراكات', subtitle: 'اضغط "تشغيل الشهر" لإنشاء اشتراكات ${_months[_month]}', actionLabel: 'تشغيل الشهر', onAction: _run)
            : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _filtered.length, itemBuilder: (ctx, i) => _card(_filtered[i], isDark))),
      ]),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton.small(heroTag: 'r', backgroundColor: AppTheme.accent, child: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
        const SizedBox(height: 8),
        FloatingActionButton.extended(heroTag: 'run', backgroundColor: AppTheme.primary, icon: const Icon(Icons.play_arrow, color: Colors.white), label: Text('تشغيل ${_months[_month]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onPressed: _run),
      ]),
    );
  }

  Widget _summaryBar(bool isDark) => Container(
    margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
    child: Column(children: [
      Row(children: [
        _mini('${_expected.toStringAsFixed(0)} ج', 'المتوقع',   AppTheme.primary),
        _mini('${_paid.toStringAsFixed(0)} ج',     'المحصّل',   AppTheme.success),
        _mini('${(_expected - _paid).toStringAsFixed(0)} ج', 'المتبقي', AppTheme.danger),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(
          value: (_rate / 100).clamp(0.0, 1.0),
          backgroundColor: const Color(0xFFE2E8F0),
          color: _rate >= 80 ? AppTheme.success : _rate >= 50 ? AppTheme.warning : AppTheme.danger,
          minHeight: 9,
        ))),
        const SizedBox(width: 8),
        Text('${_rate.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
      ]),
    ]),
  );

  Widget _mini(String v, String l, Color c) => Expanded(child: Column(children: [
    Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 13)),
    Text(l, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
  ]));

  Widget _card(Subscription sub, bool isDark) {
    final sc = sub.status == 'paid' ? AppTheme.success : sub.status == 'partial' ? AppTheme.warning : AppTheme.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: sc.withOpacity(0.25))),
      child: Column(children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(sub.studentName[0], style: TextStyle(fontWeight: FontWeight.bold, color: sc)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sub.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(sub.groupName, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ])),
          StatusBadge(label: sub.statusLabel, color: sc),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (sub.paidAmount / sub.amount).clamp(0.0, 1.0), backgroundColor: const Color(0xFFE2E8F0), color: sc, minHeight: 6))),
          const SizedBox(width: 8),
          Text('${sub.paidAmount.toStringAsFixed(0)}/${sub.amount.toStringAsFixed(0)} ج', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sc)),
        ]),
        if (sub.status != 'paid') ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.payments, size: 15), label: const Text('دفع كامل'), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.success, side: const BorderSide(color: AppTheme.success), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _pay(sub, sub.remainingAmount))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.money, size: 15), label: const Text('دفع جزئي'), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.warning, side: const BorderSide(color: AppTheme.warning), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _partialDialog(sub))),
          ]),
        ],
      ]),
    );
  }

  Future<void> _pay(Subscription sub, double amount) async {
    final s = await DatabaseHelper.instance.getStudentById(sub.studentId);
    if (s == null) return;
    await DatabaseHelper.instance.paySubscription(sub, amount, s);
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم تسجيل دفعة ${amount.toStringAsFixed(0)} ج لـ ${sub.studentName}'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
  }

  void _partialDialog(Subscription sub) {
    double a = 0;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('دفع جزئي — ${sub.studentName}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('المتبقي: ${sub.remainingAmount.toStringAsFixed(0)} ج.م', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(decoration: const InputDecoration(labelText: 'المبلغ المدفوع', suffixText: 'ج.م'), keyboardType: TextInputType.number, onChanged: (v) => a = double.tryParse(v) ?? 0),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(onPressed: () { Navigator.pop(ctx); if (a > 0) _pay(sub, a); }, child: const Text('حفظ'))],
    ));
  }

  Future<void> _run() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [const Icon(Icons.play_circle, color: AppTheme.primary), const SizedBox(width: 8), Text('تشغيل ${_months[_month]} $_year')]),
      content: const Text('سيتم إنشاء اشتراك تلقائي لكل الطلاب النشطين وخصم قيمة الاشتراك من رصيدهم.\n\nهل أنت متأكد؟'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تشغيل الآن'))],
    ));
    if (ok != true) return;
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const AlertDialog(content: Row(children: [CircularProgressIndicator(color: AppTheme.primary), SizedBox(width: 14), Text('جارٍ المعالجة...')])));
    final result = await DatabaseHelper.instance.runMonthlyEngine(_month, _year);
    if (!mounted) return;
    Navigator.pop(context);
    _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم إنشاء ${result['created']} اشتراك | تجاهل ${result['skipped']}'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 4)));
  }

  Future<void> _pickMonth() async {
    int tm = _month, ty = _year;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('اختر الشهر'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setS(() => ty--)),
          Text('$ty', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setS(() => ty++)),
        ]),
        Wrap(spacing: 8, runSpacing: 8, children: List.generate(12, (i) => GestureDetector(
          onTap: () => setS(() => tm = i + 1),
          child: Container(width: 68, padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(color: tm == i + 1 ? AppTheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: tm == i + 1 ? AppTheme.primary : const Color(0xFFE2E8F0))),
            child: Text(_months[i + 1], textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: tm == i + 1 ? Colors.white : null))),
        ))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () { setState(() { _month = tm; _year = ty; }); Navigator.pop(ctx); _load(); }, child: const Text('تأكيد')),
      ],
    )));
  }
}
