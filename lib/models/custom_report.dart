// lib/models/custom_report.dart
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'student.dart';
import 'group.dart';
import 'payment.dart';
import 'academic.dart';

class CustomReport {
  final String name;
  final ReportType type;
  final List<String> includedFields;
  final List<ReportFilter> filters;
  final ReportFormat format;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? groupId;
  
  CustomReport({
    required this.name,
    required this.type,
    required this.includedFields,
    required this.filters,
    required this.format,
    this.startDate,
    this.endDate,
    this.groupId,
  });
}

enum ReportType { students, payments, attendance, grades, financial }
enum ReportFormat { pdf, excel, csv, json }

class ReportFilter {
  final String field;
  final String operator;
  final dynamic value;
  
  ReportFilter({
    required this.field,
    required this.operator,
    required this.value,
  });
}

class ReportGenerator {
  static final ReportGenerator _instance = ReportGenerator._internal();
  factory ReportGenerator() => _instance;
  ReportGenerator._internal();
  
  // توليد التقرير
  Future<dynamic> generateReport(CustomReport report) async {
    final data = await _fetchData(report);
    
    switch (report.format) {
      case ReportFormat.pdf:
        return await _generatePdf(report, data);
      case ReportFormat.excel:
        return await _generateExcel(report, data);
      case ReportFormat.csv:
        return _generateCsv(report, data);
      case ReportFormat.json:
        return _generateJson(report, data);
    }
  }
  
  // جلب البيانات حسب المعايير
  Future<List<Map<String, dynamic>>> _fetchData(CustomReport report) async {
    final db = DatabaseHelper.instance;
    List<Map<String, dynamic>> result = [];
    
    switch (report.type) {
      case ReportType.students:
        var students = await db.getStudents();
        if (report.groupId != null) {
          students = students.where((s) => s.groupName == report.groupId).toList();
        }
        result = students.map((s) => _studentToMap(s, report.includedFields)).toList();
        break;
        
      case ReportType.payments:
        var payments = await db.getAllPayments();
        if (report.startDate != null) {
          payments = payments.where((p) => _parseDate(p.date).isAfter(report.startDate!)).toList();
        }
        if (report.endDate != null) {
          payments = payments.where((p) => _parseDate(p.date).isBefore(report.endDate!)).toList();
        }
        result = payments.map((p) => _paymentToMap(p, report.includedFields)).toList();
        break;
        
      case ReportType.attendance:
        var students = await db.getStudents();
        for (final s in students) {
          final attendance = await db.getStudentAttendance(s.id!);
          final present = attendance.where((a) => a.present).length;
          final total = attendance.length;
          result.add({
            'name': s.name,
            'group': s.groupName,
            'present': present,
            'absent': total - present,
            'percentage': total > 0 ? (present / total * 100).toStringAsFixed(1) : '0',
          });
        }
        break;
        
      case ReportType.grades:
        var students = await db.getStudents();
        for (final s in students) {
          final grades = await db.getStudentGrades(s.id!);
          final excellent = grades.where((g) => g.grade == 'excellent').length;
          final good = grades.where((g) => g.grade == 'good').length;
          final weak = grades.where((g) => g.grade == 'weak').length;
          result.add({
            'name': s.name,
            'group': s.groupName,
            'excellent': excellent,
            'good': good,
            'weak': weak,
            'average': _calculateAverage(grades),
          });
        }
        break;
        
      case ReportType.financial:
        final payments = await db.getAllPayments();
        final total = payments.fold(0.0, (s, p) => s + p.amount);
        result.add({
          'total_collected': total,
          'total_payments': payments.length,
          'last_payment': payments.isNotEmpty ? payments.first.date : 'لا يوجد',
          'monthly': await _getMonthlyBreakdown(),
        });
        break;
    }
    
    // تطبيق الفلاتر
    for (final filter in report.filters) {
      result = result.where((item) => _applyFilter(item, filter)).toList();
    }
    
    return result;
  }
  
  // توليد PDF
  Future<pw.Document> _generatePdf(CustomReport report, List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pw.PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(report.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Text('تاريخ التقرير: ${DateTime.now().toString().split(' ')[0]}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: _getHeaders(report),
            data: data.map((row) => _rowToList(row, report.includedFields)).toList(),
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
    
    return pdf;
  }
  
  // توليد Excel
  Future<Excel> _generateExcel(CustomReport report, List<Map<String, dynamic>> data) async {
    final excel = Excel.createExcel();
    final sheet = excel['Report'];
    
    // إضافة الرأس
    final headers = _getHeaders(report);
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    
    // إضافة البيانات
    for (final row in data) {
      final cells = _rowToList(row, report.includedFields);
      sheet.appendRow(cells.map((c) => TextCellValue(c.toString())).toList());
    }
    
    return excel;
  }
  
  // توليد CSV
  String _generateCsv(CustomReport report, List<Map<String, dynamic>> data) {
    final headers = _getHeaders(report);
    final rows = data.map((row) => _rowToList(row, report.includedFields).join(',')).toList();
    return [headers.join(','), ...rows].join('\n');
  }
  
  // توليد JSON
  String _generateJson(CustomReport report, List<Map<String, dynamic>> data) {
    return jsonEncode({
      'report_name': report.name,
      'generated_at': DateTime.now().toIso8601String(),
      'type': report.type.toString(),
      'data': data,
    });
  }
  
  // دوال مساعدة
  List<String> _getHeaders(CustomReport report) {
    final fieldLabels = {
      'name': 'الاسم',
      'group': 'المجموعة',
      'phone': 'الهاتف',
      'balance': 'الرصيد',
      'xp': 'نقاط XP',
      'level': 'المستوى',
      'date': 'التاريخ',
      'amount': 'المبلغ',
      'note': 'ملاحظات',
      'present': 'حاضر',
      'absent': 'غائب',
      'percentage': 'النسبة المئوية',
      'excellent': 'ممتاز',
      'good': 'جيد',
      'weak': 'ضعيف',
      'average': 'المتوسط',
    };
    
    return report.includedFields.map((f) => fieldLabels[f] ?? f).toList();
  }
  
  Map<String, dynamic> _studentToMap(Student s, List<String> fields) {
    final map = <String, dynamic>{};
    for (final field in fields) {
      switch (field) {
        case 'name': map['name'] = s.name; break;
        case 'group': map['group'] = s.groupName; break;
        case 'phone': map['phone'] = s.phone; break;
        case 'balance': map['balance'] = s.balance; break;
        case 'xp': map['xp'] = s.xp; break;
        case 'level': map['level'] = s.level; break;
      }
    }
    return map;
  }
  
  Map<String, dynamic> _paymentToMap(Payment p, List<String> fields) {
    final map = <String, dynamic>{};
    for (final field in fields) {
      switch (field) {
        case 'name': map['name'] = p.studentName; break;
        case 'date': map['date'] = p.date; break;
        case 'amount': map['amount'] = p.amount; break;
        case 'note': map['note'] = p.note; break;
      }
    }
    return map;
  }
  
  List<dynamic> _rowToList(Map<String, dynamic> row, List<String> fields) {
    return fields.map((f) => row[f] ?? '').toList();
  }
  
  bool _applyFilter(Map<String, dynamic> item, ReportFilter filter) {
    final value = item[filter.field];
    switch (filter.operator) {
      case '==': return value == filter.value;
      case '>': return value > filter.value;
      case '<': return value < filter.value;
      case '>=': return value >= filter.value;
      case '<=': return value <= filter.value;
      case 'contains': return value.toString().contains(filter.value.toString());
      default: return true;
    }
  }
  
  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('/');
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }
  
  double _calculateAverage(List<AcademicGrade> grades) {
    if (grades.isEmpty) return 0;
    double sum = 0;
    for (final g in grades) {
      switch (g.grade) {
        case 'excellent': sum += 100; break;
        case 'good': sum += 75; break;
        case 'acceptable': sum += 50; break;
        case 'weak': sum += 25; break;
      }
    }
    return sum / grades.length;
  }
  
  Future<Map<String, double>> _getMonthlyBreakdown() async {
    final payments = await DatabaseHelper.instance.getAllPayments();
    final breakdown = <String, double>{};
    for (final p in payments) {
      final month = p.date.split('/').sublist(1, 3).join('/');
      breakdown[month] = (breakdown[month] ?? 0) + p.amount;
    }
    return breakdown;
  }
}