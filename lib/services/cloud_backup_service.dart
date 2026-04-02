// lib/services/cloud_backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../database_helper.dart';
import 'backup_service.dart';

class CloudBackupService {
  static final CloudBackupService _instance = CloudBackupService._internal();
  factory CloudBackupService() => _instance;
  CloudBackupService._internal();
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['https://www.googleapis.com/auth/drive.file']);
  GoogleSignInAccount? _currentUser;
  
  // تسجيل الدخول إلى Google
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (e) {
      return false;
    }
  }
  
  // تسجيل الخروج
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }
  
  // رفع نسخة احتياطية إلى Google Drive
  Future<Map<String, dynamic>> uploadBackup() async {
    if (_currentUser == null) {
      return {'success': false, 'message': 'الرجاء تسجيل الدخول أولاً'};
    }
    
    try {
      // إنشاء نسخة احتياطية محلية
      final backupPath = await BackupService().createBackup();
      final backupFile = File(backupPath);
      final fileBytes = await backupFile.readAsBytes();
      
      // الحصول على access token
      final authHeaders = await _currentUser!.authHeaders;
      final accessToken = authHeaders['Authorization']?.replaceFirst('Bearer ', '');
      
      if (accessToken == null) {
        throw Exception('فشل في الحصول على token');
      }
      
      // إنشاء ملف على Google Drive
      final metadata = {
        'name': 'hasaty_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        'parents': ['appDataFolder'], // حفظ في مجلد بيانات التطبيق
      };
      
      final uploadUrl = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart';
      
      final boundary = '----${DateTime.now().millisecondsSinceEpoch}';
      final requestBody = '''
--$boundary
Content-Type: application/json; charset=UTF-8

${jsonEncode(metadata)}
--$boundary
Content-Type: application/json

${utf8.decode(fileBytes)}
--$boundary--
''';
      
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'multipart/related; boundary=$boundary',
        },
        body: requestBody,
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'fileId': result['id'],
          'message': 'تم رفع النسخة الاحتياطية بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': 'فشل في رفع الملف: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ: $e'};
    }
  }
  
  // تحميل النسخ الاحتياطية من Google Drive
  Future<List<Map<String, dynamic>>> listBackups() async {
    if (_currentUser == null) return [];
    
    try {
      final authHeaders = await _currentUser!.authHeaders;
      final accessToken = authHeaders['Authorization']?.replaceFirst('Bearer ', '');
      
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files?q="appDataFolder" in parents and name contains "hasaty_backup"&orderBy=createdTime desc'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List;
        return files.map((f) => {
          'id': f['id'],
          'name': f['name'],
          'created': DateTime.parse(f['createdTime']),
          'size': f['size'] ?? 0,
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  // تحميل نسخة احتياطية
  Future<Map<String, dynamic>> downloadBackup(String fileId) async {
    if (_currentUser == null) {
      return {'success': false, 'message': 'الرجاء تسجيل الدخول أولاً'};
    }
    
    try {
      final authHeaders = await _currentUser!.authHeaders;
      final accessToken = authHeaders['Authorization']?.replaceFirst('Bearer ', '');
      
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      if (response.statusCode == 200) {
        // حفظ الملف محلياً
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/restore_backup.json';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // استعادة البيانات
        final result = await BackupService().restoreBackup(filePath);
        
        // حذف الملف المؤقت
        await file.delete();
        
        return result;
      } else {
        return {'success': false, 'message': 'فشل في تحميل الملف'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ: $e'};
    }
  }
  
  // حذف نسخة احتياطية من السحابة
  Future<bool> deleteBackup(String fileId) async {
    if (_currentUser == null) return false;
    
    try {
      final authHeaders = await _currentUser!.authHeaders;
      final accessToken = authHeaders['Authorization']?.replaceFirst('Bearer ', '');
      
      final response = await http.delete(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
  
  // مزامنة تلقائية (خلفية)
  Future<void> autoSync() async {
    if (_currentUser == null) return;
    
    // يمكن جدولة مزامنة تلقائية كل أسبوع
    final lastSync = await _getLastSyncDate();
    final daysSince = DateTime.now().difference(lastSync).inDays;
    
    if (daysSince >= 7) {
      await uploadBackup();
      await _saveLastSyncDate();
    }
  }
  
  Future<DateTime> _getLastSyncDate() async {
    // قراءة من SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_cloud_sync');
    if (lastSyncStr != null) {
      return DateTime.parse(lastSyncStr);
    }
    return DateTime(2000);
  }
  
  Future<void> _saveLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_cloud_sync', DateTime.now().toIso8601String());
  }
}

// إضافة import
import 'package:shared_preferences/shared_preferences.dart';