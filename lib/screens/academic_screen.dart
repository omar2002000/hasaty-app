import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AcademicScreen extends StatefulWidget {
  const AcademicScreen();
  @override
  _AcademicScreenState createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Group> _groups = [];
  List<AcademicGrade> _recent = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final groups = await DatabaseHelper.instance.getGroups();
    final grades = await DatabaseHelper.instance.getAllGrades();
    if (!mounted) return;
    setState(() { _groups = groups; _recent = grades.take(30).toList(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقييم الأكاديمي'),
        bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
          tabs: const [Tab(text: 'تقييم سريع'), Tab(text: 'السجل')]),
      ),
      body: _loading ? const LoadingWidget() : TabBarView(controller: _tab, children: [
        _groups.isEmpty
            ? const EmptyState(icon: Icons.school_outlined, title: 'لا توجد مجموعات', subtitle: 'أضف مجموعات أولاً')
            : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _groups.length, itemBuilder: (ctx, i) => ActionTile(
                title: _groups[i].name, subtitle: '${_groups[i].monthlyPrice.toStringAsFixed(0)} ج.م / شهر',
                icon: Icons.groups, color: AppTheme.primary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupGradingScreen(group: _groups[i]))).then((_) => _load()),
              )),
        _recent.isEmpty
            ? const EmptyState(icon: Icons.history_edu, title: 'لا يوجد سجل تقييمات', subtitle: 'ابدأ بتقييم طلابك')
            : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _recent.length, itemBuilder: (ctx, i) {
                final g = _recent[i]; final isDark = Theme.of(context).brightness == Brightness.dark;
                final gc = g.grade == 'excellent' ? AppTheme.success : g.grade == 'good' ? AppTheme.accent : g.grade == 'acceptable' ? AppTheme.warning : AppTheme.danger;
                return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: gc.withOpacity(0.2))),
                  child: Row(children: [
                    Container(width: 38, height: 38, decoration: BoxDecoration(color: gc.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(g.gradeEmoji, style: const TextStyle(fontSize: 17)))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${g.typeLabel} — ${g.groupName}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      StatusBadge(label: g.gradeLabel, color: gc),
                      const SizedBox(height: 3),
                      Text(g.date, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    ]),
                  ]));
              }),
      ]),
    );
  }
}

class GroupGradingScreen extends StatefulWidget {
  final Group group;
  const GroupGradingScreen({required this.group});
  @override
  _GroupGradingScreenState createState() => _GroupGradingScreenState();
}

class _GroupGradingScreenState extends State<GroupGradingScreen> {
  List<Student> _students = [];
  Map<int, String> _grades = {};
  String _type = 'recitation', _topic = '';
  bool _loading = true;

  final _types = {'recitation': 'تسميع 🎤', 'homework': 'واجب 📝', 'exam': 'اختبار 📋'};
  final _opts = [
    {'key': 'excellent',  'label': 'ممتاز', 'emoji': '🌟', 'color': AppTheme.success, 'xp': 15},
    {'key': 'good',       'label': 'جيد',   'emoji': '✅', 'color': AppTheme.accent,   'xp': 10},
    {'key': 'acceptable', 'label': 'مقبول', 'emoji': '⚠️', 'color': AppTheme.warning,  'xp': 5},
    {'key': 'weak',       'label': 'ضعيف',  'emoji': '❌', 'color': AppTheme.danger,   'xp': 0},
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final all = await DatabaseHelper.instance.getStudents();
    if (!mounted) return;
    setState(() { _students = all.where((s) => s.groupName == widget.group.name).toList(); _loading = false; });
  }

  Future<void> _save() async {
    if (_grades.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قيّم على الأقل طالباً واحداً'), backgroundColor: AppTheme.warning, behavior: SnackBarBehavior.floating)); return; }
    final now = DateTime.now(); final date = '${now.day}/${now.month}/${now.year}';
    for (final e in _grades.entries) {
      final s = _students.firstWhere((st) => st.id == e.key);
      final opt = _opts.firstWhere((o) => o['key'] == e.value);
      final xp = opt['xp'] as int;
      await DatabaseHelper.instance.addGrade(AcademicGrade(studentId: s.id!, studentName: s.name, groupName: widget.group.name, type: _type, grade: e.value, date: date, sessionTopic: _topic));
      if (xp > 0) { s.xp += xp; await DatabaseHelper.instance.updateStudent(s); await DatabaseHelper.instance.awardCoins(s.id!, s.name, xp ~/ 2, '${_types[_type]} ${opt['label']}'); }
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم حفظ ${_grades.length} تقييم'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تقييم — ${widget.group.name}'),
        actions: [TextButton(onPressed: _save, child: const Text('حفظ الكل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))],
      ),
      body: _loading ? const LoadingWidget() : Column(children: [
        Container(
          padding: const EdgeInsets.all(12), color: AppTheme.primary.withOpacity(0.04),
          child: Column(children: [
            Row(children: _types.entries.map((e) => Expanded(child: GestureDetector(
              onTap: () => setState(() => _type = e.key),
              child: Container(margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: _type == e.key ? AppTheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: _type == e.key ? AppTheme.primary : const Color(0xFFE2E8F0))),
                child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _type == e.key ? Colors.white : AppTheme.textSecondary))),
            ))).toList()),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(hintText: 'موضوع الجلسة (اختياري)...', prefixIcon: Icon(Icons.topic_outlined), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), onChanged: (v) => _topic = v),
          ]),
        ),
        Expanded(child: _students.isEmpty
            ? const EmptyState(icon: Icons.people_outline, title: 'لا يوجد طلاب', subtitle: 'أضف طلاباً لهذه المجموعة')
            : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _students.length, itemBuilder: (ctx, i) {
                final s = _students[i]; final sel = _grades[s.id]; final isDark = Theme.of(context).brightness == Brightness.dark;
                final bc = sel != null ? (_opts.firstWhere((o) => o['key'] == sel)['color'] as Color) : const Color(0xFFE2E8F0);
                return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: bc.withOpacity(sel != null ? 0.35 : 1.0))),
                  child: Column(children: [
                    Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(s.name[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                      if (sel != null) Text(_opts.firstWhere((o) => o['key'] == sel)['emoji'] as String, style: const TextStyle(fontSize: 20)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: _opts.map((o) {
                      final isS = sel == o['key']; final c = o['color'] as Color;
                      return Expanded(child: GestureDetector(
                        onTap: () => setState(() => _grades[s.id!] = o['key'] as String),
                        child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(color: isS ? c : c.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.3))),
                          child: Column(children: [
                            Text(o['emoji'] as String, style: const TextStyle(fontSize: 13)),
                            Text(o['label'] as String, style: TextStyle(fontSize: 10, color: isS ? Colors.white : c, fontWeight: FontWeight.bold)),
                          ])),
                      ));
                    }).toList()),
                  ]));
              })),
      ]),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: ElevatedButton.icon(
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text('حفظ ${_grades.length} تقييم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: _save,
      ))),
    );
  }
}
