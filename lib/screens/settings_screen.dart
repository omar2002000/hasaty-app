import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../main.dart';
import 'whatsapp_automation_screen.dart';
import 'nasr_coins_screen.dart';
import 'archive_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: const AppBar(title: Text('الإعدادات')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]), borderRadius: BorderRadius.circular(18)), child: Row(children: [
          Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('ن', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('مستر نصر علي', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)), Text('معلم اللغة الإنجليزية', style: TextStyle(color: Colors.white70, fontSize: 12)), SizedBox(height: 5), Text('حصتي v4.0 🚀', style: TextStyle(color: Colors.white60, fontSize: 11))])),
        ])),
        const SizedBox(height: 22),
        _lbl('المظهر'),
        _tile(context, icon: isDark ? Icons.light_mode : Icons.dark_mode, color: AppTheme.purple, title: 'الوضع الليلي', subtitle: isDark ? 'مفعّل' : 'غير مفعّل', trailing: Switch(value: isDark, activeColor: AppTheme.primary, onChanged: (v) => HasatyApp.of(context)?.toggleTheme(v))),
        const SizedBox(height: 16),
        _lbl('الأدوات'),
        _tile(context, icon: Icons.campaign, color: AppTheme.success, title: 'مركز واتساب التلقائي', subtitle: 'إرسال رسائل جماعية', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhatsAppAutomationScreen()))),
        _tile(context, icon: Icons.monetization_on_outlined, color: AppTheme.warning, title: 'عملة نصر 🪙', subtitle: 'نقاط التحفيز ومتجر المكافآت', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NasrCoinsScreen()))),
        _tile(context, icon: Icons.archive_outlined, color: AppTheme.textSecondary, title: 'أرشيف الطلاب', subtitle: 'الطلاب المنقطعون', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchiveScreen()))),
        const SizedBox(height: 16),
        _lbl('عن التطبيق'),
        _tile(context, icon: Icons.info_outline, color: AppTheme.primary, title: 'الإصدار', subtitle: 'حصتي v4.0 — مستر نصر علي'),
      ])),
    );
  }
  static Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(t, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)));
  static Widget _tile(BuildContext ctx, {required IconData icon, required Color color, required String title, required String subtitle, Widget? trailing, VoidCallback? onTap}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Container(margin: const EdgeInsets.only(bottom: 7), decoration: BoxDecoration(color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard, borderRadius: BorderRadius.circular(13), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))), child: ListTile(onTap: onTap, leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 19)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)), trailing: trailing ?? (onTap != null ? Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey.shade400) : null)));
  }
}
