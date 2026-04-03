import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen();
  @override
  _ArchiveScreenState createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Student> _archived = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getArchivedStudents();
    if (!mounted) return;
    setState(() { _archived = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أرشيف الطلاب'), backgroundColor: AppTheme.textSecondary),
      body: _loading ? const LoadingWidget() : _archived.isEmpty
          ? const EmptyState(icon: Icons.archive_outlined, title: 'الأرشيف فارغ', subtitle: 'الطلاب المؤرشفون سيظهرون هنا')
          : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _archived.length, itemBuilder: (ctx, i) {
              final s = _archived[i]; final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(11)), child: Center(child: Text(s.name[0], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)), Text('${s.groupName} | رصيد: ${s.balance.toStringAsFixed(0)} ج', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))])),
                TextButton(onPressed: () async { await DatabaseHelper.instance.restoreStudent(s.id!); _load(); if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم استعادة ${s.name}'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating)); }, child: const Text('استعادة', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
              ]));
            }),
    );
  }
}
