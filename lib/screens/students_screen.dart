import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models/index.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'student_profile_screen.dart';

class StudentsScreen extends StatefulWidget {
  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> with SingleTickerProviderStateMixin {
  List<Student> _all = [], _filtered = [];
  final _search = TextEditingController();
  String _filterGroup = 'الكل';
  String _sortBy = 'الاسم';
  String _filterStatus = 'الكل';
  List<String> _groups = ['الكل'];
  bool _loading = true;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => _applyFilter());
    _search.addListener(_applyFilter);
    _loadData();
  }

  @override
  void dispose() { _tab.dispose(); _search.dispose(); super.dispose(); }

  _loadData() async {
    final data = await DatabaseHelper.instance.getStudents();
    final groups = data.map((s) => s.groupName).toSet().toList()..sort();
    setState(() {
      _all = data;
      _groups = ['الكل', ...groups];
      _loading = false;
    });
    _applyFilter();
  }

  _applyFilter() {
    List<Student> result = List.from(_all);

    // فلتر التبويب
    if (_tab.index == 1) result = result.where((s) => s.balance < 0).toList();
    if (_tab.index == 2) result = result.where((s) => s.balance >= 0).toList();

    // فلتر المجموعة
    if (_filterGroup != 'الكل') result = result.where((s) => s.groupName == _filterGroup).toList();

    // البحث
    final q = _search.text.toLowerCase();
    if (q.isNotEmpty) result = result.where((s) => s.name.toLowerCase().contains(q) || s.phone.contains(q)).toList();

    // الترتيب
    switch (_sortBy) {
      case 'الاسم': result.sort((a, b) => a.name.compareTo(b.name)); break;
      case 'الرصيد': result.sort((a, b) => a.balance.compareTo(b.balance)); break;
      case 'XP': result.sort((a, b) => b.xp.compareTo(a.xp)); break;
    }

    setState(() => _filtered = result);
  }

  _launchWhatsApp(Student s) async {
    String p = s.phone.startsWith('0') ? s.phone.substring(1) : s.phone;
    final bal = s.balance >= 0 ? 'رصيدك ${s.balance.toStringAsFixed(0)} ج.م ✅' : 'عليك ${s.balance.abs().toStringAsFixed(0)} ج.م 🙏';
    final msg = Uri.encodeComponent('أهلاً يا ${s.name}،\n$bal\nمعلمك: مستر نصر علي');
    final url = "https://wa.me/20$p?text=$msg";
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  _showChargeDialog(Student s) {
    double amount = 0; String note = '';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [Icon(Icons.add_card, color: AppTheme.primary), SizedBox(width: 8), Text('شحن رصيد — ${s.name}')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: EdgeInsets.all(12), margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: (s.balance < 0 ? AppTheme.danger : AppTheme.success).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('الرصيد الحالي: ', style: TextStyle(fontSize: 14)),
            Text('${s.balance.toStringAsFixed(0)} ج.م', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: s.balance < 0 ? AppTheme.danger : AppTheme.success)),
          ]),
        ),
        TextField(decoration: InputDecoration(labelText: 'المبلغ المدفوع', prefixIcon: Icon(Icons.payments), suffixText: 'ج.م'), keyboardType: TextInputType.number, onChanged: (v) => amount = double.tryParse(v) ?? 0),
        SizedBox(height: 12),
        TextField(decoration: InputDecoration(labelText: 'ملاحظة (اختياري)', prefixIcon: Icon(Icons.note_alt_outlined)), onChanged: (v) => note = v),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
        ElevatedButton.icon(
          icon: Icon(Icons.check, size: 16),
          label: Text('شحن'),
          onPressed: () async {
            if (amount > 0) {
              await DatabaseHelper.instance.chargeStudent(s, amount, note);
              Navigator.pop(ctx);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('✅ تم شحن ${amount.toStringAsFixed(0)} ج.م'),
                backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating,
              ));
            }
          },
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الطلاب'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white, indicatorWeight: 3,
          tabs: [
            Tab(text: 'الكل (${_all.length})'),
            Tab(text: 'مديونون'),
            Tab(text: 'بالحساب'),
          ],
        ),
      ),
      body: Column(children: [
        // شريط البحث والفلترة
        Container(
          color: AppTheme.primary.withOpacity(0.03),
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الموبايل...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _search.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear, size: 18), onPressed: () { _search.clear(); }) : null,
              ),
            ),
            SizedBox(height: 8),
            Row(children: [
              Expanded(child: _filterChip('المجموعة', _filterGroup, _groups, (v) => setState(() { _filterGroup = v; _applyFilter(); }))),
              SizedBox(width: 8),
              Expanded(child: _filterChip('الترتيب', _sortBy, ['الاسم', 'الرصيد', 'XP'], (v) => setState(() { _sortBy = v; _applyFilter(); }))),
            ]),
          ]),
        ),
        // عداد النتائج
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            Text('${_filtered.length} طالب', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            Spacer(),
            if (_filtered.isNotEmpty)
              Text('إجمالي الديون: ${_filtered.where((s) => s.balance < 0).fold(0.0, (s, st) => s + st.balance.abs()).toStringAsFixed(0)} ج',
                style: TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ),
        Expanded(
          child: _loading ? LoadingWidget() : _filtered.isEmpty
            ? EmptyState(icon: Icons.person_search, title: 'لا توجد نتائج', subtitle: 'جرّب تغيير الفلتر أو البحث')
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final s = _filtered[i];
                  return StudentCard(
                    name: s.name, group: s.groupName, phone: s.phone,
                    balance: s.balance, xp: s.xp, level: s.level, levelEmoji: s.levelEmoji,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProfileScreen(student: s))).then((_) => _loadData()),
                    onWhatsApp: () => _launchWhatsApp(s),
                    onCharge: () => _showChargeDialog(s),
                  );
                },
              ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primary,
        icon: Icon(Icons.person_add, color: Colors.white),
        label: Text('إضافة طالب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _filterChip(String label, String value, List<String> options, Function(String) onChanged) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: EdgeInsets.all(16), child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ...options.map((o) => ListTile(
            title: Text(o),
            trailing: o == value ? Icon(Icons.check, color: AppTheme.primary) : null,
            onTap: () { Navigator.pop(ctx); onChanged(o); },
          )),
          SizedBox(height: 16),
        ]),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$label: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Flexible(child: Text(value, style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          Icon(Icons.expand_more, size: 16, color: AppTheme.primary),
        ]),
      ),
    );
  }

  void _showAddDialog() {
    String name = '', phone = '', group = '';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [Icon(Icons.person_add, color: AppTheme.primary), SizedBox(width: 8), Text('إضافة طالب جديد')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(decoration: InputDecoration(labelText: 'اسم الطالب', prefixIcon: Icon(Icons.person)), onChanged: (v) => name = v),
        SizedBox(height: 12),
        TextField(decoration: InputDecoration(labelText: 'رقم الموبايل', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone, onChanged: (v) => phone = v),
        SizedBox(height: 12),
        TextField(decoration: InputDecoration(labelText: 'المجموعة', prefixIcon: Icon(Icons.groups)), onChanged: (v) => group = v),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (name.isNotEmpty) {
              await DatabaseHelper.instance.addStudent(Student(name: name, phone: phone, groupName: group));
              Navigator.pop(ctx);
              _loadData();
            }
          },
          child: Text('حفظ'),
        ),
      ],
    ));
  }
}
