// lib/services/activity_log_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ActivityLogService {
  static final ActivityLogService _instance = ActivityLogService._internal();
  factory ActivityLogService() => _instance;
  ActivityLogService._internal();

  File? _logFile;

  Future<File> _getLogFile() async {
    if (_logFile != null) return _logFile!;
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/activity_log.json');
    if (!await _logFile!.exists()) {
      await _logFile!.writeAsString('[]');
    }
    return _logFile!;
  }

  Future<void> log({
    required String action,
    String? userName,
    Map<String, dynamic>? details,
  }) async {
    try {
      final file = await _getLogFile();
      final content = await file.readAsString();
      List<dynamic> logs = [];
      if (content.isNotEmpty) {
        logs = jsonDecode(content);
      }
      logs.add({
        'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'action': action,
        'userName': userName,
        'details': details ?? {},
      });
      await file.writeAsString(jsonEncode(logs));
    } catch (e) {
      // تجاهل الأخطاء في التسجيل
    }
  }

  Future<List<Map<String, dynamic>>> getLogs({int? limit}) async {
    try {
      final file = await _getLogFile();
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      List<dynamic> logs = jsonDecode(content);
      List<Map<String, dynamic>> result = logs.cast<Map<String, dynamic>>();
      if (limit != null && limit > 0) {
        result = result.reversed.take(limit).toList().reversed.toList();
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  Future<void> clearLogs() async {
    try {
      final file = await _getLogFile();
      await file.writeAsString('[]');
    } catch (e) {
      // تجاهل الأخطاء
    }
  }
}