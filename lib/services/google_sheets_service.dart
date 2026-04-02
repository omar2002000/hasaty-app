// lib/services/google_sheets_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database_helper.dart';
import '../models.dart';

class GoogleSheetsService {
  static const String _baseUrl = 'https://sheets.googleapis.com/v4/spreadsheets';
  String? _apiKey;
  String? _spreadsheetId;
  
  GoogleSheetsService({String? apiKey, String? spreadsheetId}) {
    _apiKey = apiKey;
    _spreadsheetId = spreadsheetId;
  }
  
  // تعيين معرف جدول البيانات
  void setSpreadsheetId(String id) {
    _spreadsheetId = id;
  }
  
  // تعيين مفتاح API
  void setApiKey(String key) {
    _apiKey = key;
  }
  
  // تصدير الطلاب إلى Google Sheets
  Future<bool> exportStudentsToSheets() async {
    if (_apiKey == null || _spreadsheetId == null) {
      throw Exception('API Key أو Spreadsheet ID غير مضبوط');
    }
    
    final students = await DatabaseHelper.instance.getStudents();
    final values = [
      ['الاسم', 'المجموعة', 'الرصيد', 'XP', 'المستوى', 'تاريخ الانضمام'],
      ...students.map((s) => [
        s.name,
        s.groupName,
        s.balance.toString(),
        s.xp.toString(),
        s.level,
        s.joinDate,
      ]),
    ];
    
    final body = {
      'values': values,
      'majorDimension': 'ROWS',
    };
    
    final url = '$_baseUrl/$_spreadsheetId/values/Students!A1:append'
        '?valueInputOption=RAW&key=$_apiKey';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    
    return response.statusCode == 200;
  }
  
  // تصدير التقارير المالية
  Future<bool> exportFinancialReport(int month, int year) async {
    final payments = await DatabaseHelper.instance.getAllPayments();
    final monthStr = '/$month/$year';
    final monthlyPayments = payments.where((p) => p.date.endsWith(monthStr)).toList();
    
    final values = [
      ['التاريخ', 'الطالب', 'المبلغ', 'ملاحظات'],
      ...monthlyPayments.map((p) => [
        p.date,
        p.studentName,
        p.amount.toString(),
        p.note,
      ]),
    ];
    
    final body = {
      'values': values,
      'majorDimension': 'ROWS',
    };
    
    final url = '$_baseUrl/$_spreadsheetId/values/Financial!A1:append'
        '?valueInputOption=RAW&key=$_apiKey';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    
    return response.statusCode == 200;
  }
  
  // تصدير سجل الحضور
  Future<bool> exportAttendanceReport(DateTime date) async {
    final students = await DatabaseHelper.instance.getStudents();
    final dateStr = '${date.day}/${date.month}/${date.year}';
    
    List<List<dynamic>> values = [
      ['الاسم', 'المجموعة', 'الحضور'],
    ];
    
    for (final s in students) {
      final attendance = await DatabaseHelper.instance.getStudentAttendance(s.id!);
      final present = attendance.any((a) => a.date == dateStr && a.present);
      values.add([s.name, s.groupName, present ? 'حاضر' : 'غائب']);
    }
    
    final body = {
      'values': values,
      'majorDimension': 'ROWS',
    };
    
    final url = '$_baseUrl/$_spreadsheetId/values/Attendance!A1:append'
        '?valueInputOption=RAW&key=$_apiKey';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    
    return response.statusCode == 200;
  }
  
  // مزامنة البيانات من Google Sheets
  Future<Map<String, dynamic>> syncFromSheets() async {
    if (_apiKey == null || _spreadsheetId == null) {
      throw Exception('API Key أو Spreadsheet ID غير مضبوط');
    }
    
    final url = '$_baseUrl/$_spreadsheetId/values/Students!A:F?key=$_apiKey';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode != 200) {
      throw Exception('فشل في قراءة البيانات');
    }
    
    final data = jsonDecode(response.body);
    final rows = data['values'] as List?;
    
    if (rows == null || rows.isEmpty) {
      return {'success': false, 'message': 'لا توجد بيانات'};
    }
    
    int imported = 0;
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length >= 3) {
        final student = Student(
          name: row[0],
          groupName: row[1],
          phone: '', // يحتاج تحديث يدوي
          balance: double.tryParse(row[2]) ?? 0,
          xp: int.tryParse(row[3]) ?? 0,
        );
        await DatabaseHelper.instance.addStudent(student);
        imported++;
      }
    }
    
    return {
      'success': true,
      'message': 'تم استيراد $imported طالب',
      'count': imported,
    };
  }
  
  // إنشاء جدول بيانات جديد
  Future<String?> createSpreadsheet(String title) async {
    if (_apiKey == null) throw Exception('API Key غير مضبوط');
    
    final body = {
      'properties': {'title': title},
      'sheets': [
        {'properties': {'title': 'Students'}},
        {'properties': {'title': 'Financial'}},
        {'properties': {'title': 'Attendance'}},
      ],
    };
    
    final url = 'https://sheets.googleapis.com/v4/spreadsheets?key=$_apiKey';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['spreadsheetId'];
    }
    
    return null;
  }
}