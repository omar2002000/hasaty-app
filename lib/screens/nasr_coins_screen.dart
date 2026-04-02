import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class NasrCoinsScreen extends StatefulWidget {
  @override
  _NasrCoinsScreenState createState() => _NasrCoinsScreenState();
}

class _NasrCoinsScreenState extends State<NasrCoinsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;

  final _rewards = [
    {'title': 'خصم 10% على المذكرة',  'coins': 50,  'icon': Icons.book,              'color': AppTheme.primary},
    {'title': 'حصة مجانية',            'coins': 100, 'icon': Icons.free_breakfast,    'color': AppTheme.success},
    {'title': 'شهادة تميز',            'coins': 75,  'icon': Icons.workspace_premium, 'color': AppTheme.warning},
    {'title': 'هدية من المستر',        'coins': 150, 'icon': Icons.card_giftcard,     'color': AppTheme.purple},
    {'title': 'خصم 50% على الاشتراك', 'coins': 200, 'icon': Icons.percent,           'color': AppTheme.accent},
    {'title': 'نجم الشهر',            'coins': 500, 'icon': Icons.star,              'color': AppTheme.warning},
  ];

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  _load() async {
    final lb = await DatabaseHelper.instance.getCoinsLeaderboard();
    setState(() { _leaderboard = lb; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [Text('🪙', style: TextStyle(fontSize: 20)), SizedBox(width: 8), Text('عملة نصر')]),
        bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
          tabs: [Tab(text: 'ترتيب الطلاب'), Tab(text: 'سوق المكافآت')]),
      ),
      body: _loading ? LoadingWidget() : TabBarView(controller: _tab, children: [_leaderboardTab(), _rewardsTab()]),
    );
  }

  Widget _leaderboardTab() {
    if (_leaderboard.isEmpty) return EmptyState(icon: Icons.monetization_on, title: 'لا توجد عملات بعد', subtitle: 'تُمنح العملات عند التقييم والحضور');
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      itemBuilder: (ctx, i) {
        final item = _leaderboard[i];
        final coins = item['totalCoins'] as int;
        final name = item['name'] as String;
        final medals = ['🥇','🥈','🥉'];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: i < 3 ? AppTheme.warning.withOpacity(0.07) : (isDark ? AppTheme.bgCardDark : AppTheme.bgCard),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: i < 3 ? AppTheme.warning.withOpacity(0.2) : Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            SizedBox(width: 32, child: Center(child: i < 3 ? Text(medals[i], style: TextStyle(fontSize: 20)) : Text('${i+1}', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)))),
            SizedBox(width: 10),
            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(name[0], style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)))),
            SizedBox(width: 10),
            Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.bold))),
            Text('🪙 $coins', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning, fontSize: 14)),
          ]),
        );
      },
    );
  }

  Widget _rewardsTab() => ListView.builder(
    padding: EdgeInsets.all(16),
    itemCount: _rewards.length,
    itemBuilder: (ctx, i) {
      final r = _rewards[i];
      final color = r['color'] as Color;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        margin: EdgeInsets.only(bottom: 12), padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(r['icon'] as IconData, color: color, size: 24)),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Row(children: [Text('🪙 ', style: TextStyle(fontSize: 13)), Text('${r['coins']} عملة', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold))]),
          ])),
          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 تم طلب المكافأة: ${r['title']}'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating)),
            style: ElevatedButton.styleFrom(backgroundColor: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            child: Text('صرف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
      );
    },
  );
}
