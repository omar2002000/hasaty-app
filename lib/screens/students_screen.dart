import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'student_profile_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen();
  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> with SingleTickerProviderStateMixin {
  List<Student> _all = [], _filtered = [];
  final _search = TextEditingController();
  String _filterGroup = 'الكل', _sortBy = 'XP';
  List<String> _groups = ['الكل'];
  bool _loading = true;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => _apply());
    _search.addListener(_apply);
    _loadData();
  }

  @override
  void dispose() { _tab.dispose(); _search.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    final data = await DatabaseHelper.instance.getStudents();
    final groups = data.map((s) => s.groupName).toSet().toList()..sort();
    if (!mounted) return;
    setState(() { _all = data; _groups = ['الكل', ...groups]; _loading = false; });
    _apply();
  }

  void _apply() {
    List<Student> r = List.from(_all);
    if (_tab.index == 1) r = r.where((s) => s.balance < 0).toList();
    if (_tab.index == 2) r = r.where((s) => s.balance >= 0).toList();
    if (_filterGroup != 'الكل') r = r.where((s) => s.groupName == _filterGroup).toList();
    final q = _search.text.toLowerCase();
    if (q.isNotEmpty) r = r.where((s) => s.name.toLowerCase().contains(q) || s.phone.contains(q)).toList();
    switch (_sortBy) {
      case 'الاسم':  r.sort((a, b) => a.name.compareTo(b.name)); break;
      case 'الرصيد': r.sort((a, b) => a.balance.compareTo(b.balance)); break;
      default:        r.sort((a, b) => b.xp.compareTo(a.xp));
    }
    if (mounted) setState(() => _filtered = r);
  }

  Future<void> _launchWhatsApp(Student s) async {
    final p = s.phone.startsWith('0') ? s.phone.substring(1) : s.phone;
    final msg = Uri.encodeComponent(s.balance >= 0
        ? WhatsAppTemplates.debt(s.name, s.balance.toStringAsFixed(0))
        : WhatsAppTemplates.debt(s.name, s.balance.abs().toStringAsFixed(0)));
    final url = Uri.parse('https://wa.me/20$p?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _showChargeDialog(Student s) {
    double amount = 0; String note = '';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [const Icon(Icons.add_card, color: AppTheme.primary), const SizedBox(width: 8), Text('شحن رصيد — ${s.name}')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: (s.balance < 0 ? AppTheme.danger : AppTheme.success).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('الرصيد الحالي: ', style: TextStyle(fontSize: 14)),
            Text('${s.balance.toStringAsFixed(0)} ج.م', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: s.balance < 0 ? AppTheme.danger : AppTheme.success)),
          ])),
        TextField(decoration: const InputDecoration(labelText: 'المبلغ المدفوع', prefixIcon: Icon(Icons.payments), suffixText: 'ج.م'), keyboardType: TextInputType.number, onChanged: (v) => amount = double.tryParse(v) ?? 0),
        const SizedBox(height: 10),
        TextField(decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)', prefixIcon: Icon(Icons.note_alt_outlined)), onChanged: (v) => note = v),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton.icon(
          icon: const Icon(Icons.check, size: 16),
          label: const Text('شحن'),
          onPressed: () async {
            if (amount <= 0) return;
            await DatabaseHelper.instance.chargeStudent(s, amount, note);
            if (!mounted) return;
            Navigator.pop(ctx);
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم شحن ${amount.toStringAsFixed(0)} ج.م'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
          },
        ),
      ],
    ));
  }

  void _showAddDialog() {
    String name = '', phone = '', group = '';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [Icon(Icons.person_add, color: AppTheme.primary), SizedBox(width: 8), Text('إضافة طالب جديد')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(decoration: const InputDecoration(labelText: 'اسم الطالب', prefixIcon: Icon(Icons.person)), onChanged: (v) => name = v),
        const SizedBox(height: 10),
        TextField(decoration: const InputDecoration(labelText: 'رقم الموبايل', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone, onChanged: (v) => phone = v),
        const SizedBox(height: 10),
        TextField(decoration: const InputDecoration(labelText: 'المجموعة', prefixIcon: Icon(Icons.groups)), onChanged: (v) => group = v),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (name.isEmpty) return;
            await DatabaseHelper.instance.addStudent(Student(name: name, phone: phone, groupName: group));
            if (!mounted) return;
            Navigator.pop(ctx);
            _loadData();
          },
          child: const Text('حفظ'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الطلاب (${_all.length})'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
          tabs: [Tab(text: 'الكل (${_all.length})'), const Tab(text: 'مديونون'), const Tab(text: 'بالحساب')],
        ),
      ),
      body: Column(children: [
        Container(
          color: AppTheme.primary.withOpacity(0.03),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'بحث باسم الطالب أو الموبايل...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _search.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _search.clear(); }) : null,
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _chip('المجموعة', _filterGroup, _groups, (v) { setState(() => _filterGroup = v); _apply(); })),
              const SizedBox(width: 8),
              Expanded(child: _chip('الترتيب', _sortBy, ['XP', 'الاسم', 'الرصيد'], (v) { setState(() => _sortBy = v); _apply(); })),
            ]),
          ]),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : _filtered.isEmpty
                  ? const EmptyState(icon: Icons.person_search, title: 'لا توجد نتائج', subtitle: 'جرّب تغيير الفلتر أو البحث')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final s = _filtered[i];
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final isDebt = s.balance < 0;
                        final sc = isDebt ? AppTheme.danger : AppTheme.success;
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProfileScreen(student: s))).then((_) => _loadData()),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDebt ? AppTheme.danger.withOpacity(0.25) : const Color(0xFFE2E8F0)),
                            ),
                            child: Column(children: [
                              Row(children: [
                                Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Center(child: Text(s.name[0], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)))),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Flexible(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 6),
                                    StatusBadge(label: '${s.levelEmoji} ${s.level}', color: _lvlColor(s.level)),
                                  ]),
                                  Text(s.groupName, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('${s.balance.abs().toStringAsFixed(0)} ج', style: TextStyle(fontWeight: FontWeight.bold, color: sc, fontSize: 15)),
                                  Text(isDebt ? 'دين' : 'رصيد', style: TextStyle(fontSize: 10, color: sc)),
                                ]),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                Text('XP: ${s.xp}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (s.xp / 500).clamp(0.0, 1.0), backgroundColor: const Color(0xFFE2E8F0), color: _lvlColor(s.level), minHeight: 5))),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                _iconBtn(Icons.add_card, AppTheme.primary, 'شحن',    () => _showChargeDialog(s)),
                                const SizedBox(width: 8),
                                _iconBtn(Icons.chat,     AppTheme.success, 'واتساب', () => _launchWhatsApp(s)),
                                const SizedBox(width: 8),
                                Expanded(child: GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProfileScreen(student: s))).then((_) => _loadData()),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Icon(Icons.person, size: 14, color: AppTheme.primary),
                                      SizedBox(width: 4),
                                      Text('الملف', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                    ]),
                                  ),
                                )),
                              ]),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('إضافة طالب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _chip(String label, String value, List<String> options, Function(String) onChanged) => GestureDetector(
    onTap: () => showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: const EdgeInsets.all(14), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
      ...options.map((o) => ListTile(title: Text(o), trailing: o == value ? const Icon(Icons.check, color: AppTheme.primary) : null, onTap: () { Navigator.pop(ctx); onChanged(o); })),
      const SizedBox(height: 14),
    ])),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.primary.withOpacity(0.2))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        const Icon(Icons.expand_more, size: 16, color: AppTheme.primary),
      ]),
    ),
  );

  Widget _iconBtn(IconData icon, Color color, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color), const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ]),
    ),
  );

  Color _lvlColor(String l) {
    switch (l) {
      case 'نجم':    return AppTheme.warning;
      case 'متقدم': return AppTheme.purple;
      case 'متوسط': return AppTheme.primaryLight;
      default:      return AppTheme.success;
    }
  }
}
