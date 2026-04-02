// lib/services/export_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database_helper.dart';
import '../models.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();
  
  // تصدير إلى Excel
  Future<File> exportToExcel({
    required String fileName,
    required List<Map<String, dynamic>> data,
    required List<String> headers,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    
    // إضافة الرأس
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    
    // إضافة البيانات
    for (final row in data) {
      final cells = headers.map((h) => TextCellValue(row[h]?.toString() ?? '')).toList();
      sheet.appendRow(cells);
    }
    
    // حفظ الملف
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
    
    return file;
  }
  
  // تصدير إلى PDF
  Future<File> exportToPdf({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> headers,
    List<String>? footers,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Text('تاريخ التصدير: ${DateTime.now().toString().split(' ')[0]}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: headers,
            data: data.map((row) => headers.map((h) => row[h]?.toString() ?? '').toList()).toList(),
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          if (footers != null) ...[
            pw.SizedBox(height: 40),
            pw.Divider(),
            ...footers.map((f) => pw.Text(f, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
          ],
        ],
      ),
    );
    
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$title.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  // تصدير قائمة الطلاب
  Future<File> exportStudentsList() async {
    final students = await DatabaseHelper.instance.getStudents();
    final data = students.map((s) => {
      'الاسم': s.name,
      'المجموعة': s.groupName,
      'الهاتف': s.phone,
      'الرصيد': s.balance.toStringAsFixed(0),
      'نقاط XP': s.xp.toString(),
      'المستوى': s.level,
      'تاريخ الانضمام': s.joinDate,
    }).toList();
    
    final headers = ['الاسم', 'المجموعة', 'الهاتف', 'الرصيد', 'نقاط XP', 'المستوى', 'تاريخ الانضمام'];
    
    return await exportToExcel(
      fileName: 'students_list_${DateTime.now().millisecondsSinceEpoch}',
      data: data,
      headers: headers,
    );
  }
  
  // تصدير التقرير المالي
  Future<File> exportFinancialReport(int month, int year) async {
    final payments = await DatabaseHelper.instance.getAllPayments();
    final monthStr = '/$month/$year';
    final monthlyPayments = payments.where((p) => p.date.endsWith(monthStr)).toList();
    
    final total = monthlyPayments.fold(0.0, (s, p) => s + p.amount);
    
    final data = monthlyPayments.map((p) => {
      'التاريخ': p.date,
      'الطالب': p.studentName,
      'المبلغ': p.amount.toStringAsFixed(0),
      'ملاحظات': p.note,
    }).toList();
    
    final headers = ['التاريخ', 'الطالب', 'المبلغ', 'ملاحظات'];
    final footers = [
      '',
      'إجمالي التحصيل: ${total.toStringAsFixed(0)} ج.م',
      'عدد الدفعات: ${monthlyPayments.length}',
    ];
    
    final months = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 
                    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    
    return await exportToPdf(
      title: 'التقرير المالي - ${months[month]} $year',
      data: data,
      headers: headers,
      footers: footers,
    );
  }
  
  // تصدير سجل الحضور
  Future<File> exportAttendanceReport(DateTime date) async {
    final students = await DatabaseHelper.instance.getStudents();
    final dateStr = '${date.day}/${date.month}/${date.year}';
    
    List<Map<String, dynamic>> data = [];
    for (final s in students) {
      final attendance = await DatabaseHelper.instance.getStudentAttendance(s.id!);
      final present = attendance.any((a) => a.date == dateStr && a.present);
      data.add({
        'الاسم': s.name,
        'المجموعة': s.groupName,
        'الحضور': present ? '✅ حاضر' : '❌ غائب',
      });
    }
    
    final headers = ['الاسم', 'المجموعة', 'الحضور'];
    
    return await exportToExcel(
      fileName: 'attendance_${date.day}_${date.month}_${date.year}',
      data: data,
      headers: headers,
    );
  }
  
  // تصدير تقرير التقييمات
  Future<File> exportGradesReport(String groupName) async {
    final students = await DatabaseHelper.instance.getStudents();
    final groupStudents = students.where((s) => s.groupName == groupName).toList();
    
    List<Map<String, dynamic>> data = [];
    for (final s in groupStudents) {
      final grades = await DatabaseHelper.instance.getStudentGrades(s.id!);
      final excellent = grades.where((g) => g.grade == 'excellent').length;
      final good = grades.where((g) => g.grade == 'good').length;
      final weak = grades.where((g) => g.grade == 'weak').length;
      
      data.add({
        'الاسم': s.name,
        'ممتاز': excellent,
        'جيد': good,
        'ضعيف': weak,
        'المجموع': grades.length,
      });
    }
    
    final headers = ['الاسم', 'ممتاز', 'جيد', 'ضعيف', 'المجموع'];
    
    return await exportToExcel(
      fileName: 'grades_${groupName}_${DateTime.now().millisecondsSinceEpoch}',
      data: data,
      headers: headers,
    );
  }
  
  // مشاركة الملف
  Future<void> shareFile(File file, String message) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: message,
    );
  }
}