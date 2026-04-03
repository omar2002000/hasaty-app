import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'groups_screen.dart';
import 'academic_screen.dart';
import 'nasr_coins_screen.dart';
import 'notifications_screen.dart';
import 'whatsapp_automation_screen.dart';
import 'session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen();
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _students = 0, _unread = 0;
  double _debt = 0, _income = 0;
  List<Student> _top = [], _debtList = [];
  bool _loading = true;

  final _months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final students = await db.getStudents();
    final income   = await db.getTotalCollectedThisMonth();
    final debts    = await db.getStudentsWithDebt();
    final unread   = await db.getUnreadCount();
    if (!mounted) return;
    setState(() {
      _students  = students.length;
      _debt      = debts.fold(0.0, (s, st) => s + st.balance.abs());
      _income    = income;
      _top       = students.take(3).toList();
      _debtList  = debts.take(3).toList();
      _unread    = unread;
      _loading   = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now    = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: _loading
          ? const LoadingWidget()
          : CustomScrollView(slivers: [
              _buildAppBar(now, isDark),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  Row(children: [
                    StatCard(title: 'الطلاب',       value: '$_students',                          icon: Icons.people,      color: AppTheme.primary),
                    const SizedBox(width: 8),
                    StatCard(title: 'الديون',        value: '${_debt.toStringAsFixed(0)} ج',       icon: Icons.money_off,   color: AppTheme.danger),
                    const SizedBox(width: 8),
                    StatCard(title: 'تحصيل الشهر',  value: '${_income.toStringAsFixed(0)} ج',     icon: Icons.trending_up, color: AppTheme.success),
                  ]),
                  const SizedBox(height: 14),
                  _quickSession(),
                  const SizedBox(height: 14),
                  const SectionHeader(title: 'أدوات سريعة'),
                  const SizedBox(height: 8),
                  Row(children: [
                    _tool('تقييم الطلاب', Icons.rate_review,    AppTheme.purple,  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademicScreen())).then((_) => _load())),
                    const SizedBox(width: 8),
                    _tool('واتساب ذكي',   Icons.send_to_mobile,  AppTheme.success, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhatsAppAutomationScreen()))),
                    const SizedBox(width: 8),
                    _tool('عملة نصر 🪙', Icons.monetization_on,  AppTheme.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NasrCoinsScreen()))),
                  ]),
                  if (_debtList.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const SectionHeader(title: '⚠️ يحتاجون متابعة'),
                    const SizedBox(height: 6),
                    ..._debtList.map((s) => _debtTile(s, isDark)),
                  ],
                  if (_top.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const SectionHeader(title: '🏆 لوحة الشرف'),
                    const SizedBox(height: 6),
                    _honorRow(),
                  ],
                  const SizedBox(height: 20),
                  Center(child: Text('حصتي v4.0 — مستر نصر علي', style: TextStyle(color: Colors.grey.shade400, fontSize: 10))),
                  const SizedBox(height: 20),
                ])),
              ),
            ]),
    );
  }

  SliverAppBar _buildAppBar(DateTime now, bool isDark) => SliverAppBar(
    expandedHeight: 160,
    pinned: true,
    backgroundColor: AppTheme.primary,
    actions: [
      Stack(children: [
        IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())).then((_) => _load())),
        if (_unread > 0)
          Positioned(right: 8, top: 8, child: Container(
            width: 14, height: 14,
            decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
            child: Center(child: Text('$_unread', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
          )),
      ]),
    ],
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('ن', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('مرحباً، مستر نصر علي 👋', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('معلم اللغة الإنجليزية',   style: TextStyle(color: Colors.white70, fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text('${_months[now.month]} ${now.year}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        )),
      ),
      title: const Text('حصتي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      titlePadding: const EdgeInsets.only(right: 16, bottom: 14),
    ),
  );

  Widget _quickSession() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.success, Color(0xFF059669)]), borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('بدء حصة الآن',        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        Text('تحضير + خصم + تقييم', style: TextStyle(color: Colors.white70, fontSize: 11)),
      ])),
      ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsPickerScreen())).then((_) => _load()),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
        child: const Text('ابدأ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ]),
  );

  Widget _tool(String label, IconData icon, Color color, VoidCallback onTap) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ]),
    ),
  ));

  Widget _debtTile(Student s, bool isDark) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: isDark ? AppTheme.danger.withOpacity(0.1) : AppTheme.danger.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.danger.withOpacity(0.15))),
    child: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.12), borderRadius: BorderRadius.circular(9)), child: Center(child: Text(s.name[0], style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(s.groupName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ])),
      Text('${s.balance.abs().toStringAsFixed(0)} ج', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _honorRow() => Row(children: _top.asMap().entries.map((e) {
    final s = e.value; final i = e.key;
    const medals  = ['🥇', '🥈', '🥉'];
    final colors = [AppTheme.warning, Colors.grey, const Color(0xFFCD7F32)];
    return Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: colors[i].withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors[i].withOpacity(0.25))),
      child: Column(children: [
        Text(medals[i], style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(s.name.split(' ').first, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('${s.xp} XP', style: TextStyle(fontSize: 10, color: colors[i], fontWeight: FontWeight.bold)),
      ]),
    ));
  }).toList());
}

// شاشة اختيار المجموعة لبدء الحصة
class GroupsPickerScreen extends StatefulWidget {
  const GroupsPickerScreen();
  @override
  _GroupsPickerScreenState createState() => _GroupsPickerScreenState();
}

class _GroupsPickerScreenState extends State<GroupsPickerScreen> {
  List<Group> _groups = [];
  @override
  void initState() { super.initState(); DatabaseHelper.instance.getGroups().then((g) => setState(() => _groups = g)); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('اختر المجموعة'), backgroundColor: AppTheme.success),
    body: _groups.isEmpty
        ? const EmptyState(icon: Icons.groups_outlined, title: 'لا توجد مجموعات', subtitle: 'أضف مجموعات أولاً')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _groups.length,
            itemBuilder: (ctx, i) {
              final g = _groups[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: AppTheme.success.withOpacity(0.15), child: const Icon(Icons.groups, color: AppTheme.success)),
                  title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${g.monthlyPrice.toStringAsFixed(0)} ج.م / شهر'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SessionScreen(group: g))),
                ),
              );
            },
          ),
  );
}
