import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'whatsapp_automation_screen.dart';
import 'nasr_coins_screen.dart';
import 'archive_screen.dart';
import 'underperforming_screen.dart';
import '../models/index.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // بطاقة المعلم
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18)),
                child: const Center(child: Text('ن', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('مستر نصر علي', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('معلم اللغة الإنجليزية', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('حصتي v4.0 🚀', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ])),
            ]),
          ),

          const SizedBox(height: 24),
          const _Label('المظهر'),
          _Tile(
            context,
            icon: isDark ? Icons.light_mode : Icons.dark_mode,
            color: AppTheme.purple,
            title: 'الوضع الليلي',
            subtitle: isDark ? 'مفعّل' : 'غير مفعّل',
            trailing: Switch(
              value: isDark,
              activeColor: AppTheme.primary,
              onChanged: _toggleTheme,
            ),
          ),

          const SizedBox(height: 16),
          const _Label('الأدوات'),
          _Tile(
            context,
            icon: Icons.campaign,
            color: AppTheme.success,
            title: 'مركز واتساب التلقائي',
            subtitle: 'إرسال رسائل جماعية وتقارير',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WhatsAppAutomationScreen())),
          ),
          _Tile(
            context,
            icon: Icons.monetization_on_outlined,
            color: AppTheme.warning,
            title: 'عملة نصر 🪙',
            subtitle: 'نقاط التحفيز ومتجر المكافآت',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NasrCoinsScreen())),
          ),
          _Tile(
            context,
            icon: Icons.warning_amber_outlined,
            color: AppTheme.danger,
            title: 'فلتر المقصرين',
            subtitle: 'طلاب يحتاجون متابعة عاجلة',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UnderperformingScreen())),
          ),
          _Tile(
            context,
            icon: Icons.archive_outlined,
            color: AppTheme.textSecondary,
            title: 'أرشيف الطلاب',
            subtitle: 'الطلاب المنقطعون',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArchiveScreen())),
          ),

          const SizedBox(height: 16),
          const _Label('البيانات'),
          _Tile(
            context,
            icon: Icons.backup_outlined,
            color: AppTheme.success,
            title: 'نسخ احتياطي',
            subtitle: 'قريباً في الإصدار القادم',
          ),
          _Tile(
            context,
            icon: Icons.delete_sweep_outlined,
            color: AppTheme.danger,
            title: 'مسح البيانات',
            subtitle: 'حذف كل البيانات بشكل نهائي',
            onTap: () => _confirmClear(context),
          ),

          const SizedBox(height: 16),
          const _Label('عن التطبيق'),
          _Tile(
            context,
            icon: Icons.info_outline,
            color: AppTheme.primary,
            title: 'الإصدار',
            subtitle: 'حصتي v4.0 — مستر نصر علي',
          ),
          _Tile(
            context,
            icon: Icons.layers_outlined,
            color: AppTheme.accent,
            title: 'المراحل المكتملة',
            subtitle: '✅ الواجهة | ✅ الاشتراكات | ✅ الذكاء | ✅ التواصل',
          ),
        ]),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.warning, color: AppTheme.danger), SizedBox(width: 8), Text('تحذير!')]),
        content: const Text('سيتم حذف جميع البيانات نهائياً بما فيها الطلاب والمجموعات والمدفوعات.\n\nهذه العملية لا يمكن التراجع عنها.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('محمي — غير متاح', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
    );
  }
}

class _Tile extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile(
    this.context, {
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(this.context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary) : null),
      ),
    );
  }
}