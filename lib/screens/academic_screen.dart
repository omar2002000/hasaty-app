// أول سطرين في الملف
import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/index.dart';  // ✅ غير هذا السطر
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/whatsapp_service.dart';

class AcademicScreen extends StatefulWidget {
  final Group? group;
  const AcademicScreen({super.key, this.group});

  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Student> _students = [];
  List<Group> _groups = [];
  Group? _selectedGroup;
  String _sessionType = 'recitation';
  Map<int, String> _grades = {};
  bool _loading = true;

  final List<Map<String, dynamic>> _types = const [
    {'key': 'recitation', 'label': 'تسميع', 'icon': Icons.record_voice_over, 'color': AppTheme.primary},
    {'key': 'homework', 'label': 'واجب', 'icon': Icons.assignment, 'color': AppTheme.accent},
    {'key': 'exam', 'label': 'اختبار', 'icon': Icons.quiz, 'color': AppTheme.purple},
  ];

  final List<Map<String, dynamic>> _gradeOptions = const [
    {'key': 'excellent', 'label': 'ممتاز', 'color': AppTheme.success},
    {'key': 'good', 'label': 'جيد', 'color': AppTheme.primary},
    {'key': 'acceptable', 'label': 'مقبول', 'color': AppTheme.warning},
    {'key': 'weak', 'label': 'ضعيف', 'color': AppTheme.danger},
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _selectedGroup = widget.group;
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final groups = await DatabaseHelper.instance.getGroups();
    setState(() {
      _groups = groups;
      _loading = false;
    });
    if (_selectedGroup != null) _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (_selectedGroup == null) return;
    final all = await DatabaseHelper.instance.getStudents();
    setState(() {
      _students = all.where((s) => s.groupName == _selectedGroup!.name).toList();
      _grades = {};
    });
  }

  String _today() {
    final n = DateTime.now();
    return '${n.day}/${n.month}/${n.year}';
  }

  Future<void> _saveAll() async {
    if (_grades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم تقيّم أي طالب'), backgroundColor: AppTheme.warning, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    for (final entry in _grades.entries) {
      final student = _students.firstWhere((s) => s.id == entry.key);
      await DatabaseHelper.instance.addAcademicRecord(AcademicRecord(
        studentId: entry.key,
        studentName: student.name,
        groupName: _selectedGroup!.name,
        type: _sessionType,
        grade: entry.value,
        date: _today(),
      ));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ حُفظ ${_grades.length} تقييم'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
    );
    setState(() => _grades = {});
  }

  Future<void> _sendAll() async {
    final graded = _students.where((s) => _grades.containsKey(s.id)).toList();
    if (graded.isEmpty) return;

    for (final student in graded) {
      await WhatsAppService.send(student.phone, WhatsAppService.gradeMessage(student, _sessionType, _grades[student.id]!));
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Color _getGradeColor(String grade) {
    final option = _gradeOptions.firstWhere((g) => g['key'] == grade, orElse: () => _gradeOptions.last);
    return option['color'] as Color;
  }

  String _getGradeLabel(String grade) {
    final option = _gradeOptions.firstWhere((g) => g['key'] == grade, orElse: () => _gradeOptions.last);
    return option['label'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقييم الأكاديمي'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'تقييم سريع'), Tab(text: 'المقصرون')],
        ),
      ),
      body: _loading ? const LoadingWidget() : TabBarView(controller: _tab, children: [_gradeTab(), _weakTab()]),
    );
  }

  Widget _gradeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primary.withOpacity(0.03),
          child: Column(
            children: [
              DropdownButtonFormField<Group>(
                value: _selectedGroup,
                decoration: const InputDecoration(labelText: 'اختر المجموعة', prefixIcon: Icon(Icons.groups)),
                items: _groups.map((g) => DropdownMenuItem(value: g, child: Text(g.name))).toList(),
                onChanged: (g) {
                  setState(() => _selectedGroup = g);
                  _loadStudents();
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: _types.map((t) {
                  final sel = _sessionType == t['key'];
                  final c = t['color'] as Color;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _sessionType = t['key'] as String),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? c : c.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? c : c.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Icon(t['icon'] as IconData, color: sel ? Colors.white : c, size: 20),
                            const SizedBox(height: 4),
                            Text(t['label'] as String, style: TextStyle(color: sel ? Colors.white : c, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        if (_selectedGroup == null)
          const Expanded(child: EmptyState(icon: Icons.groups, title: 'اختر مجموعة', subtitle: 'لبدء التقييم'))
        else if (_students.isEmpty)
          const Expanded(child: EmptyState(icon: Icons.person_off, title: 'لا يوجد طلاب', subtitle: 'لا يوجد طلاب في هذه المجموعة'))
        else ...[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (ctx, i) {
                final s = _students[i];
                final sel = _grades[s.id];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sel != null ? _getGradeColor(sel).withOpacity(0.3) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Center(child: Text(s.name[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          if (sel != null) StatusBadge(label: _getGradeLabel(sel), color: _getGradeColor(sel)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: _gradeOptions.map((g) {
                          final isSel = sel == g['key'];
                          final c = g['color'] as Color;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                if (isSel) {
                                  _grades.remove(s.id);
                                } else {
                                  _grades[s.id!] = g['key'] as String;
                                }
                              }),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? c : c.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(g['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : c)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.send, size: 14),
                    label: const Text('إرسال واتساب'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.success, side: const BorderSide(color: AppTheme.success), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _sendAll,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save, size: 14, color: Colors.white),
                    label: const Text('حفظ', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _saveAll,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _weakTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getWeakStudents(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const LoadingWidget();
        final weak = snapshot.data!;
        if (weak.isEmpty) {
          return const EmptyState(icon: Icons.verified, title: 'لا يوجد مقصرون', subtitle: 'جميع الطلاب بمستوى جيد 🎉');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: weak.length,
          itemBuilder: (ctx, i) {
            final s = weak[i]['student'] as Student;
            final wc = weak[i]['weakCount'] as int;
            final pct = weak[i]['attendance'] as double;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(s.name[0], style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(s.groupName, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (wc > 0) StatusBadge(label: '$wc ضعيف', color: AppTheme.danger),
                          if (pct < 50) ...[
                            const SizedBox(height: 4),
                            StatusBadge(label: '${pct.toStringAsFixed(0)}% حضور', color: AppTheme.warning),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.send, size: 14),
                      label: const Text('إرسال تنبيه واتساب'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () => WhatsAppService.send(s.phone, WhatsAppService.warningMessage(s, pct)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}