import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      ),
    ));
  }
}

class ActionTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionTile({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey.shade400),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 11, color: color), const SizedBox(width: 3)],
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      if (action != null)
        GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500))),
    ]),
  );
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: AppTheme.primary),
      SizedBox(height: 14),
      Text('جارٍ التحميل...', style: TextStyle(color: AppTheme.textSecondary)),
    ]),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({required this.icon, required this.title, required this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, size: 44, color: AppTheme.primary.withOpacity(0.5))),
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 7),
        Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        if (actionLabel != null) ...[
          const SizedBox(height: 22),
          ElevatedButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(actionLabel!)),
        ],
      ]),
    ),
  );
}
