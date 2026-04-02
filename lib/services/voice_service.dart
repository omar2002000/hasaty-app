// lib/services/voice_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'notification_service.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();
  
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  
  // التحقق من توفر الإدخال الصوتي
  Future<bool> isAvailable() async {
    return await _speech.initialize();
  }
  
  // بدء الاستماع
  Future<String?> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    if (!await isAvailable()) {
      onError('الإدخال الصوتي غير متوفر');
      return null;
    }
    
    _isListening = true;
    
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          _isListening = false;
          onResult(text);
        }
      },
      onSoundLevelChange: (level) {
        // تحديث مستوى الصوت
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 2),
    );
    
    return null;
  }
  
  // إيقاف الاستماع
  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }
  
  // معالجة الأوامر الصوتية
  Future<Map<String, dynamic>> processCommand(String command) async {
    final lowerCommand = command.toLowerCase();
    
    // تسجيل الحضور
    if (lowerCommand.contains('حضر') || lowerCommand.contains('حاضر')) {
      final studentName = _extractName(lowerCommand);
      if (studentName != null) {
        return await _markAttendance(studentName);
      }
    }
    
    // استعلام عن رصيد
    if (lowerCommand.contains('رصيد')) {
      final studentName = _extractName(lowerCommand);
      if (studentName != null) {
        return await _getBalance(studentName);
      }
    }
    
    // إضافة طالب
    if (lowerCommand.contains('أضف طالب')) {
      return {'action': 'add_student', 'need_more_info': true};
    }
    
    // تقرير
    if (lowerCommand.contains('تقرير')) {
      if (lowerCommand.contains('حضور')) {
        return {'action': 'attendance_report'};
      }
      if (lowerCommand.contains('مالي')) {
        return {'action': 'financial_report'};
      }
      return {'action': 'general_report'};
    }
    
    // بدء حصة
    if (lowerCommand.contains('بدء حصة')) {
      final groupName = _extractGroup(lowerCommand);
      return {'action': 'start_session', 'group': groupName};
    }
    
    return {'action': 'unknown', 'command': command};
  }
  
  // تسجيل الحضور بالصوت
  Future<Map<String, dynamic>> _markAttendance(String studentName) async {
    final students = await DatabaseHelper.instance.getStudents();
    final student = students.firstWhere(
      (s) => s.name.toLowerCase().contains(studentName.toLowerCase()),
      orElse: () => throw Exception('الطالب غير موجود'),
    );
    
    final groups = await DatabaseHelper.instance.getGroups();
    final group = groups.firstWhere(
      (g) => g.name == student.groupName,
      orElse: () => throw Exception('المجموعة غير موجودة'),
    );
    
    final result = await DatabaseHelper.instance.markAttendanceByQR(
      student.id!,
      group.name,
      group.price,
    );
    
    return {
      'action': 'attendance',
      'success': result['success'],
      'message': result['message'],
      'student': student.name,
    };
  }
  
  // استعلام عن الرصيد
  Future<Map<String, dynamic>> _getBalance(String studentName) async {
    final students = await DatabaseHelper.instance.getStudents();
    final student = students.firstWhere(
      (s) => s.name.toLowerCase().contains(studentName.toLowerCase()),
      orElse: () => throw Exception('الطالب غير موجود'),
    );
    
    return {
      'action': 'balance',
      'student': student.name,
      'balance': student.balance,
      'message': student.balance >= 0 
          ? 'رصيد ${student.name} هو ${student.balance.toStringAsFixed(0)} ج.م'
          : 'على ${student.name} مبلغ ${student.balance.abs().toStringAsFixed(0)} ج.م',
    };
  }
  
  // استخراج اسم الطالب من الأمر
  String? _extractName(String command) {
    // قائمة الأسماء المحتملة - يمكن توسيعها
    final studentsList = _getCachedStudents();
    for (final name in studentsList) {
      if (command.contains(name.toLowerCase())) {
        return name;
      }
    }
    return null;
  }
  
  // استخراج اسم المجموعة
  String? _extractGroup(String command) {
    final groups = _getCachedGroups();
    for (final group in groups) {
      if (command.contains(group.toLowerCase())) {
        return group;
      }
    }
    return null;
  }
  
  // كاش مؤقت لأسماء الطلاب
  List<String> _cachedStudentNames = [];
  List<String> _cachedGroupNames = [];
  
  Future<List<String>> _getCachedStudents() async {
    if (_cachedStudentNames.isEmpty) {
      final students = await DatabaseHelper.instance.getStudents();
      _cachedStudentNames = students.map((s) => s.name.toLowerCase()).toList();
    }
    return _cachedStudentNames;
  }
  
  Future<List<String>> _getCachedGroups() async {
    if (_cachedGroupNames.isEmpty) {
      final groups = await DatabaseHelper.instance.getGroups();
      _cachedGroupNames = groups.map((g) => g.name.toLowerCase()).toList();
    }
    return _cachedGroupNames;
  }
  
  // تحديث الكاش
  void refreshCache() {
    _cachedStudentNames.clear();
    _cachedGroupNames.clear();
  }
}