import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/index.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Subscription> _subs = [];
  bool _loading = true;
  late int _month, _year;

  final months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
    final now = DateTime.now();
    _month = now.month; _year = now.year;
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  _load() async {
    setState(() => _loading = true);
    final data = await DatabaseHelper.instance.getSubscriptions(month: _month, year: _year);
    setState(() { _subs = data; _loading = false; });
  }

  List<Subscription> get _filtered {
    switch (_tab.index) {
      case 1: return _subs.where((s) => s.status == 'unpaid').toList();
      case 2: return _subs.where((s) => s.status == 'partial').toList();
      default: return _subs;
    }
  }

  double get _totalExpected => _subs.fold(0.0, (s, x) => s + x.amount);
  double get _totalPaid => _subs.fold(0.0, (s, x) => s + x.paidAmount);
  double get _collectionRate => _totalExpected > 0 ? _totalPaid / _totalExpected * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('الاشتراكات الشهرية'),
        actions: [
          // اختيار الشهر
          TextButton.icon(
            icon: Icon(Icons.calendar_month, color: Colors.white, size: 16),
            label: Text('${months[_month]} $_year', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: _pickMonth,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [Tab(text: 'الكل (${_subs.length})'), Tab(text: 'غير مدفوع'), Tab(text: 'جزئي')],
        ),
      ),
      body: Column(children: [
        // ملخص مالي
        if (!_loading) _summaryBar(isDark),
        Expanded(
          child: _loading ? LoadingWidget() : _filtered.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long,
                title: 'لا توجد اشتراكات',
                subtitle: 'اضغط "تشغيل الشهر" لإنشاء اشتراكات ${months[_month]}',
                actionLabel: 'تشغيل الشهر الآن',
                onAction: _runMonthlyEngine,
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) => _subCard(_filtered[i], isDark),
              ),
        ),
      ]),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton.small(
          heroTag: 'refresh',
          backgroundColor: AppTheme.accent,
          child: Icon(Icons.refresh, color: Colors.white),
          onPressed: _load,
        ),
        SizedBox(height: 8),
        FloatingActionButton.extended(
          heroTag: 'run',
          backgroundColor: AppTheme.primary,
          icon: Icon(Icons.play_arrow, color: Colors.white),
          label: Text('تشغيل ${months[_month]}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: _runMonthlyEngine,
        ),
      ]),
    );
  }

  Widget _summaryBar(bool isDark) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Color(0xFF334155) : Color(0xFFE2E8F0)),
      ),
      child: Column(children: [
        Row(children: [
          _miniStat('المتوقع', '${_totalExpected.toStringAsFixed(0)} ج', AppTheme.primary),
          _miniStat('المحصّل', '${_totalPaid.toStringAsFixed(0)} ج', AppTheme.success),
          _miniStat('المتبقي', '${(_totalExpected - _totalPaid).toStringAsFixed(0)} ج', AppTheme.danger),
        ]),
        SizedBox(height: 10),
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_collectionRate / 100).clamp(0.0, 1.0),
              backgroundColor: Color(0xFFE2E8F0),
              color: _collectionRate >= 80 ? AppTheme.success : _collectionRate >= 50 ? AppTheme.warning : AppTheme.danger,
              minHeight: 10,
            ),
          )),
          SizedBox(width: 10),
          Text('${_collectionRate.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
    Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
  ]));

  Widget _subCard(Subscription sub, bool isDark) {
    final statusColor = sub.status == 'paid' ? AppTheme.success : sub.status == 'partial' ? AppTheme.warning : AppTheme.danger;
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Column(children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(sub.studentName[0], style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)))),
          SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sub.studentName, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(sub.groupName, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ])),
          StatusBadge(label: sub.statusLabel, color: statusColor),
        ]),
        SizedBox(height: 10),
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (sub.paidAmount / sub.amount).clamp(0.0, 1.0),
              backgroundColor: Color(0xFFE2E8F0), color: statusColor, minHeight: 6,
            ),
          )),
          SizedBox(width: 10),
          Text('${sub.paidAmount.toStringAsFixed(0)}/${sub.amount.toStringAsFixed(0)} ج', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
        ]),
        if (sub.status != 'paid') ...[
          SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: Icon(Icons.payments, size: 16),
              label: Text('دفع كامل'),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.success, side: BorderSide(color: AppTheme.success), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => _paySubscription(sub, sub.remainingAmount),
            )),
            SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              icon: Icon(Icons.money, size: 16),
              label: Text('دفع جزئي'),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.warning, side: BorderSide(color: AppTheme.warning), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => _showPartialPayDialog(sub),
            )),
          ]),
        ],
      ]),
    );
  }

  _paySubscription(Subscription sub, double amount) async {
    final student = await DatabaseHelper.instance.getStudentById(sub.studentId);
    if (student == null) return;
    await DatabaseHelper.instance.paySubscription(sub, amount, student);
    _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ تم تسجيل دفعة ${amount.toStringAsFixed(0)} ج لـ ${sub.studentName}'),
      backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating,
    ));
  }

  _showPartialPayDialog(Subscription sub) {
    double amount = 0;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('دفع جزئي — ${sub.studentName}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('المتبقي: ${sub.remainingAmount.toStringAsFixed(0)} ج.م', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        TextField(decoration: InputDecoration(labelText: 'المبلغ المدفوع', suffixText: 'ج.م'), keyboardType: TextInputType.number, onChanged: (v) => amount = double.tryParse(v) ?? 0),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); if (amount > 0) _paySubscription(sub, amount); }, child: Text('حفظ')),
      ],
    ));
  }

  _runMonthlyEngine() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [Icon(Icons.play_circle, color: AppTheme.primary), SizedBox(width: 8), Text('تشغيل ${months[_month]} $_year')]),
      content: Text('سيتم إنشاء اشتراك تلقائي لكل الطلاب النشطين وخصم قيمة الاشتراك من رصيدهم.\n\nهل أنت متأكد؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('تشغيل الآن')),
      ],
    ));
    if (confirm != true) return;

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      content: Row(children: [CircularProgressIndicator(color: AppTheme.primary), SizedBox(width: 16), Text('جارٍ المعالجة...')]),
    ));

    final result = await DatabaseHelper.instance.runMonthlyEngine(_month, _year);
    Navigator.pop(context);
    _load();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ تم إنشاء ${result['created']} اشتراك | تجاهل ${result['skipped']}'),
      backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 4),
    ));
  }

  _pickMonth() async {
    int tempMonth = _month, tempYear = _year;
    await showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('اختر الشهر'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: Icon(Icons.chevron_left), onPressed: () => setS(() { tempYear--; })),
            Text('$tempYear', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: Icon(Icons.chevron_right), onPressed: () => setS(() { tempYear++; })),
          ]),
          Wrap(spacing: 8, runSpacing: 8, children: List.generate(12, (i) => GestureDetector(
            onTap: () => setS(() => tempMonth = i + 1),
            child: Container(
              width: 70, padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: tempMonth == i + 1 ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tempMonth == i + 1 ? AppTheme.primary : Color(0xFFE2E8F0)),
              ),
              child: Text(months[i + 1], textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: tempMonth == i + 1 ? Colors.white : null)),
            ),
          ))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(onPressed: () { setState(() { _month = tempMonth; _year = tempYear; }); Navigator.pop(ctx); _load(); }, child: Text('تأكيد')),
        ],
      ));
    });
  }
}
