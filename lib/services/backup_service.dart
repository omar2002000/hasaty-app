// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  // إنشاء نسخة احتياطية
  Future<String> createBackup({bool includeMedia = false}) async {
    try {
      final db = DatabaseHelper.instance;
      final students = await db.getStudents(includeArchived: true);
      final groups = await db.getGroups();
      final payments = await db.getAllPayments();
      final subscriptions = await db.getSubscriptions();
      final attendance = await _getAllAttendance();
      final grades = await _getAllGrades();
      final activities = await ActivityLogService().getAllLogs();

      final backupData = {
        'version': '5.0',
        'createdAt': DateTime.now().toIso8601String(),
        'appVersion': '4.0',
        'data': {
          'students': students.map((s) => s.toMap()).toList(),
          'groups': groups.map((g) => g.toMap()).toList(),
          'payments': payments.map((p) => p.toMap()).toList(),
          'subscriptions': subscriptions.map((s) => s.toMap()).toList(),
          'attendance': attendance,
          'grades': grades,
          'activities': activities,
        },
        'statistics': {
          'totalStudents': students.length,
          'totalGroups': groups.length,
          'totalPayments': payments.length,
          'totalCollections': payments.fold(0.0, (s, p) => s + p.amount),
        }
      };

      final jsonString = jsonEncode(backupData);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'hasaty_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('فشل إنشاء النسخة الاحتياطية: $e');
    }
  }

  // استعادة النسخة الاحتياطية
  Future<Map<String, dynamic>> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود');
      }

      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString);

      final db = DatabaseHelper.instance;
      final database = await db.database;

      // بدء معاملة
      await database.transaction((txn) async {
        // مسح البيانات الحالية
        await txn.delete('students');
        await txn.delete('groups');
        await txn.delete('payments');
        await txn.delete('subscriptions');
        await txn.delete('attendance');
        await txn.delete('grades');
        await txn.delete('student_achievements');
        await txn.delete('notifications');
        await txn.delete('coin_transactions');

        // إدخال البيانات الجديدة
        final data = backupData['data'];
        
        for (var s in data['students']) {
          await txn.insert('students', s);
        }
        for (var g in data['groups']) {
          await txn.insert('groups', g);
        }
        for (var p in data['payments']) {
          await txn.insert('payments', p);
        }
        for (var s in data['subscriptions']) {
          await txn.insert('subscriptions', s);
        }
        for (var a in data['attendance']) {
          await txn.insert('attendance', a);
        }
        for (var g in data['grades']) {
          await txn.insert('grades', g);
        }
      });

      return {
        'success': true,
        'message': 'تم استعادة النسخة الاحتياطية بنجاح',
        'restoredAt': DateTime.now(),
      };
    } catch (e) {
      throw Exception('فشل استعادة النسخة الاحتياطية: $e');
    }
  }

  // مشاركة النسخة الاحتياطية
  Future<void> shareBackup(BuildContext context) async {
    try {
      final filePath = await createBackup();
      await Share.shareXFiles([XFile(filePath)],
          text: 'نسخة احتياطية من تطبيق حصتي - مستر نصر علي');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // قائمة النسخ الاحتياطية المحفوظة
  Future<List<Map<String, dynamic>>> getBackupList() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = await directory.list().where((f) => 
      f.path.contains('hasaty_backup_') && f.path.endsWith('.json')
    ).toList();

    List<Map<String, dynamic>> backups = [];
    for (var file in files) {
      final stat = await file.stat();
      backups.add({
        'name': file.path.split('/').last,
        'path': file.path,
        'size': stat.size,
        'created': stat.modified,
      });
    }
    backups.sort((a, b) => b['created'].compareTo(a['created']));
    return backups;
  }

  // حذف نسخة احتياطية
  Future<void> deleteBackup(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // دوال مساعدة
  Future<List<Map<String, dynamic>>> _getAllAttendance() async {
    final db = DatabaseHelper.instance;
    final database = await db.database;
    final res = await database.query('attendance');
    return res;
  }

  Future<List<Map<String, dynamic>>> _getAllGrades() async {
    final db = DatabaseHelper.instance;
    final database = await db.database;
    final res = await database.query('grades');
    return res;
  }
}