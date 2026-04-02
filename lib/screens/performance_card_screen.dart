// lib/screens/performance_card_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../database_helper.dart';
import '../models.dart';
import '../services/export_service.dart';

class PerformanceCardScreen extends StatefulWidget {
  final Student student;
  const PerformanceCardScreen({super.key, required this.student});
  
  @override
  State<PerformanceCardScreen> createState() => _PerformanceCardScreenState();
}

class _PerformanceCardScreenState extends State<PerformanceCardScreen> {
  late Student _student;
  double _attendance = 0;
  List<AcademicGrade> _grades = [];
  Map<String, dynamic> _summary = {};
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _loadData();
  }
  
  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final attendance = await db.getAttendancePercentage(_student.id!);
    final grades = await db.getStudentGrades(_student.id!);
    final summary = await db.getStudentAcademicSummary(_student.id!);
    
    setState(() {
      _attendance = attendance;
      _grades = grades;
      _summary = summary;
      _loading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('بطاقة أداء ${_student.name}'),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareCard,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportAsPdf,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 20),
                  _buildProgress(),
                  const SizedBox(height: 20),
                  _buildGradesSummary(),
                  const SizedBox(height: 20),
                  _buildRecentGrades(),
                  const SizedBox(height: 20),
                  _buildRecommendations(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _student.name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _student.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _student.groupName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_student.levelEmoji} ${_student.level}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'نقاط XP',
            '${_student.xp}',
            Icons.stars,
            AppTheme.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'نسبة الحضور',
            '${_attendance.toStringAsFixed(0)}%',
            Icons.calendar_today,
            _attendance >= 75 ? AppTheme.success : AppTheme.danger,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'الرصيد',
            '${_student.balance.toStringAsFixed(0)} ج',
            Icons.account_balance_wallet,
            _student.balance >= 0 ? AppTheme.success : AppTheme.danger,
          ),
        ),
      ],
    );
  }
  
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgress() {
    final progress = _student.xp / _student.nextLevelXp;
    final remaining = _student.nextLevelXp - _student.xp;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقدم نحو ${_getNextLevelName()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_student.xp}/${_student.nextLevelXp} XP',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              color: _getLevelColor(),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'يتبقى $remaining نقطة للمستوى التالي',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGradesSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 ملخص التقييمات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _gradeSummaryItem('ممتاز', _summary['excellent'] ?? 0, AppTheme.success),
              _gradeSummaryItem('جيد', _summary['good'] ?? 0, AppTheme.primary),
              _gradeSummaryItem('مقبول', _summary['acceptable'] ?? 0, AppTheme.warning),
              _gradeSummaryItem('ضعيف', _summary['weak'] ?? 0, AppTheme.danger),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المعدل العام'),
                Text(
                  '${(_summary['average'] ?? 0).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _gradeSummaryItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentGrades() {
    if (_grades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('لا توجد تقييمات مسجلة بعد'),
        ),
      );
    }
    
    final recent = _grades.take(5).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 آخر التقييمات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...recent.map((g) => ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: _getGradeColor(g.grade).withOpacity(0.1),
              child: Text(
                g.type == 'recitation' ? '🎤' : g.type == 'homework' ? '📖' : '📝',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            title: Text(
              _getGradeLabel(g.grade),
              style: TextStyle(
                color: _getGradeColor(g.grade),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(g.date),
            trailing: Text(
              g.type == 'recitation' ? 'تسميع' : g.type == 'homework' ? 'واجب' : 'اختبار',
              style: const TextStyle(fontSize: 12),
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.warning),
              SizedBox(width: 8),
              Text(
                'توصيات للتحسين',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_attendance < 75)
            _recommendationItem(
              'تحسين نسبة الحضور',
              'نسبة الحضور الحالية ${_attendance.toStringAsFixed(0)}%',
              Icons.calendar_today,
            ),
          if ((_summary['weak'] ?? 0) > 0)
            _recommendationItem(
              'مراجعة المواد الضعيفة',
              'يوجد ${_summary['weak']} تقييم ضعيف',
              Icons.auto_stories,
            ),
          if (_student.balance < 0)
            _recommendationItem(
              'تسوية الرصيد',
              'المبلغ المستحق: ${_student.balance.abs().toStringAsFixed(0)} ج.م',
              Icons.payments,
            ),
          if (_student.xp < 200)
            _recommendationItem(
              'زيادة نقاط XP',
              'شارك في الأنشطة والتقييمات',
              Icons.emoji_events,
            ),
        ],
      ),
    );
  }
  
  Widget _recommendationItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.warning, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _shareCard() async {
    // إنشاء صورة للبطاقة ومشاركتها
    // يمكن استخدام screenshot أو share package
    await Share.share(
      'بطاقة أداء ${_student.name}\n'
      'المجموعة: ${_student.groupName}\n'
      'نقاط XP: ${_student.xp}\n'
      'المستوى: ${_student.level}\n'
      'نسبة الحضور: ${_attendance.toStringAsFixed(0)}%\n'
      'المعدل العام: ${(_summary['average'] ?? 0).toStringAsFixed(1)}%\n\n'
      'تطبيق حصتي - مستر نصر علي',
    );
  }
  
  Future<void> _exportAsPdf() async {
    final data = [
      {
        'الاسم': _student.name,
        'المجموعة': _student.groupName,
        'نقاط XP': _student.xp,
        'المستوى': _student.level,
        'نسبة الحضور': '${_attendance.toStringAsFixed(0)}%',
        'المعدل العام': '${(_summary['average'] ?? 0).toStringAsFixed(1)}%',
      }
    ];
    
    final headers = ['الاسم', 'المجموعة', 'نقاط XP', 'المستوى', 'نسبة الحضور', 'المعدل العام'];
    
    final file = await ExportService().exportToPdf(
      title: 'بطاقة أداء ${_student.name}',
      data: data,
      headers: headers,
      footers: ['تطبيق حصتي - مستر نصر علي', 'تاريخ التصدير: ${DateTime.now().toString().split(' ')[0]}'],
    );
    
    await ExportService().shareFile(file, 'بطاقة أداء ${_student.name}');
  }
  
  String _getNextLevelName() {
    if (_student.level == 'مبتدئ') return 'متوسط';
    if (_student.level == 'متوسط') return 'متقدم';
    if (_student.level == 'متقدم') return 'نجم';
    return 'نجم';
  }
  
  Color _getLevelColor() {
    if (_student.level == 'مبتدئ') return Colors.green;
    if (_student.level == 'متوسط') return Colors.blue;
    if (_student.level == 'متقدم') return Colors.orange;
    return AppTheme.warning;
  }
  
  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'excellent': return AppTheme.success;
      case 'good': return AppTheme.primary;
      case 'acceptable': return AppTheme.warning;
      default: return AppTheme.danger;
    }
  }
  
  String _getGradeLabel(String grade) {
    switch (grade) {
      case 'excellent': return 'ممتاز';
      case 'good': return 'جيد';
      case 'acceptable': return 'مقبول';
      default: return 'ضعيف';
    }
  }
}