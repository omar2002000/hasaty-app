// lib/services/recommendation_service.dart
import '../database_helper.dart';
import '../models.dart';

class RecommendationService {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  // توصيات للطلاب
  Future<List<Map<String, dynamic>>> getStudentRecommendations(Student student) async {
    List<Map<String, dynamic>> recommendations = [];
    
    final attendance = await DatabaseHelper.instance.getAttendancePercentage(student.id!);
    final grades = await DatabaseHelper.instance.getStudentGrades(student.id!);
    final weakCount = grades.where((g) => g.grade == 'weak').length;
    final debt = student.balance < 0 ? student.balance.abs() : 0;
    
    // توصيات مالية
    if (debt > 500) {
      recommendations.add({
        'type': 'financial',
        'priority': 'high',
        'title': 'اتصال ولي أمر عاجل',
        'description': 'دين متراكم بقيمة $debt ج.م يحتاج متابعة فورية',
        'icon': Icons.warning,
        'color': Colors.red,
        'action': 'call_parent',
      });
    } else if (debt > 200) {
      recommendations.add({
        'type': 'financial',
        'priority': 'medium',
        'title': 'تذكير بالسداد',
        'description': 'المبلغ المستحق: $debt ج.م',
        'icon': Icons.payments,
        'color': Colors.orange,
        'action': 'send_reminder',
      });
    }
    
    // توصيات حضور
    if (attendance < 40) {
      recommendations.add({
        'type': 'attendance',
        'priority': 'high',
        'title': 'عقد اجتماع مناقشة أسباب الغياب',
        'description': 'نسبة الحضور: ${attendance.toStringAsFixed(0)}%',
        'icon': Icons.meeting_room,
        'color': Colors.red,
        'action': 'schedule_meeting',
      });
    } else if (attendance < 60) {
      recommendations.add({
        'type': 'attendance',
        'priority': 'medium',
        'title': 'متابعة الغياب',
        'description': 'نسبة الحضور منخفضة: ${attendance.toStringAsFixed(0)}%',
        'icon': Icons.warning_amber,
        'color': Colors.orange,
        'action': 'send_absence_warning',
      });
    }
    
    // توصيات أكاديمية
    if (weakCount >= 3) {
      recommendations.add({
        'type': 'academic',
        'priority': 'high',
        'title': 'جلسة تقوية خاصة',
        'description': 'حصل على $weakCount تقييمات ضعيفة',
        'icon': Icons.school,
        'color': Colors.orange,
        'action': 'schedule_remedial',
      });
    } else if (weakCount >= 1) {
      recommendations.add({
        'type': 'academic',
        'priority': 'low',
        'title': 'مراجعة المواد الضعيفة',
        'description': 'يحتاج متابعة في ${_getWeakSubjects(grades)}',
        'icon': Icons.auto_stories,
        'color': Colors.blue,
        'action': 'show_material',
      });
    }
    
    // توصيات تحفيزية
    final xpProgress = student.xp / student.nextLevelXp;
    if (xpProgress > 0.8 && student.level != 'نجم') {
      recommendations.add({
        'type': 'motivational',
        'priority': 'medium',
        'title': 'قريب من المستوى التالي!',
        'description': '${(xpProgress * 100).toStringAsFixed(0)}% من ${student.nextLevelXp} XP',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'action': 'show_rewards',
      });
    }
    
    // ترتيب حسب الأولوية
    recommendations.sort((a, b) => 
      _getPriorityWeight(b['priority']).compareTo(_getPriorityWeight(a['priority']))
    );
    
    return recommendations;
  }
  
  // توصيات للمجموعة
  Future<List<Map<String, dynamic>>> getGroupRecommendations(Group group) async {
    List<Map<String, dynamic>> recommendations = [];
    
    final students = await DatabaseHelper.instance.getStudents();
    final groupStudents = students.where((s) => s.groupName == group.name).toList();
    
    if (groupStudents.isEmpty) return recommendations;
    
    // حساب متوسطات المجموعة
    double avgAttendance = 0;
    double avgBalance = 0;
    int totalWeak = 0;
    
    for (final s in groupStudents) {
      final attendance = await DatabaseHelper.instance.getAttendancePercentage(s.id!);
      final grades = await DatabaseHelper.instance.getStudentGrades(s.id!);
      avgAttendance += attendance;
      avgBalance += s.balance;
      totalWeak += grades.where((g) => g.grade == 'weak').length;
    }
    
    avgAttendance /= groupStudents.length;
    avgBalance /= groupStudents.length;
    
    if (avgAttendance < 60) {
      recommendations.add({
        'type': 'group_attendance',
        'title': 'نسبة حضور منخفضة',
        'description': 'متوسط حضور المجموعة: ${avgAttendance.toStringAsFixed(0)}%',
        'action': 'improve_attendance',
      });
    }
    
    if (avgBalance < -200) {
      recommendations.add({
        'type': 'group_financial',
        'title': 'مشاكل مالية في المجموعة',
        'description': 'متوسط الديون: ${avgBalance.abs().toStringAsFixed(0)} ج.م',
        'action': 'contact_parents',
      });
    }
    
    if (totalWeak > groupStudents.length) {
      recommendations.add({
        'type': 'group_academic',
        'title': 'ضعف أكاديمي عام',
        'description': '$totalWeak تقييم ضعيف في المجموعة',
        'action': 'adjust_teaching',
      });
    }
    
    return recommendations;
  }
  
  // توصيات للمعلم
  Future<List<Map<String, dynamic>>> getTeacherRecommendations() async {
    List<Map<String, dynamic>> recommendations = [];
    
    final students = await DatabaseHelper.instance.getStudents();
    final totalStudents = students.length;
    final debtStudents = students.where((s) => s.balance < -300).length;
    final weakStudents = await _getWeakStudentsCount();
    
    if (debtStudents > totalStudents * 0.3) {
      recommendations.add({
        'title': 'نسبة عالية من المديونين',
        'description': '$debtStudents طالب عليهم ديون كبيرة',
        'suggestion': 'تواصل مع أولياء الأمور بشكل جماعي',
      });
    }
    
    if (weakStudents > totalStudents * 0.2) {
      recommendations.add({
        'title': 'كثرة التقييمات الضعيفة',
        'description': '$weakStudents طالب لديهم تقييمات ضعيفة',
        'suggestion': 'اعتماد أسلوب تدريس مختلف للمجموعات المتأخرة',
      });
    }
    
    return recommendations;
  }
  
  // التنبؤ بالطلاب المعرضين للخطر
  Future<List<Student>> predictAtRiskStudents() async {
    final students = await DatabaseHelper.instance.getStudents();
    List<Student> atRisk = [];
    
    for (final s in students) {
      final attendance = await DatabaseHelper.instance.getAttendancePercentage(s.id!);
      final grades = await DatabaseHelper.instance.getStudentGrades(s.id!);
      final weakCount = grades.where((g) => g.grade == 'weak').length;
      final recentPayment = await _hasRecentPayment(s.id!);
      
      // خوارزمية التنبؤ
      int riskScore = 0;
      if (attendance < 40) riskScore += 40;
      if (attendance < 60) riskScore += 20;
      if (weakCount >= 3) riskScore += 30;
      if (weakCount >= 1) riskScore += 10;
      if (s.balance < -500) riskScore += 30;
      if (s.balance < -200) riskScore += 15;
      if (!recentPayment) riskScore += 20;
      
      if (riskScore >= 60) {
        atRisk.add(s);
      }
    }
    
    atRisk.sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
    return atRisk;
  }
  
  // دوال مساعدة
  int _getPriorityWeight(String priority) {
    switch (priority) {
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': return 1;
      default: return 0;
    }
  }
  
  String _getWeakSubjects(List<AcademicGrade> grades) {
    final weakGrades = grades.where((g) => g.grade == 'weak').toList();
    if (weakGrades.isEmpty) return '';
    return weakGrades.map((g) => g.type).join('، ');
  }
  
  Future<int> _getWeakStudentsCount() async {
    final students = await DatabaseHelper.instance.getStudents();
    int count = 0;
    for (final s in students) {
      final grades = await DatabaseHelper.instance.getStudentGrades(s.id!);
      if (grades.where((g) => g.grade == 'weak').length >= 2) count++;
    }
    return count;
  }
  
  Future<bool> _hasRecentPayment(int studentId) async {
    final payments = await DatabaseHelper.instance.getStudentPayments(studentId);
    if (payments.isEmpty) return false;
    
    final lastPayment = payments.first;
    final lastDate = _parseDate(lastPayment.date);
    final daysSince = DateTime.now().difference(lastDate).inDays;
    
    return daysSince < 45; // آخر دفعة خلال 45 يوم
  }
  
  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }
}