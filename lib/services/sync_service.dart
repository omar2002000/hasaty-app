// lib/services/sync_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';
import '../models.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final List<Map<String, dynamic>> _pendingOperations = [];
  bool _isSyncing = false;
  
  // بدء مراقبة الاتصال
  Future<void> startMonitoring() async {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // تحميل العمليات المعلقة
    await _loadPendingOperations();
  }
  
  // إيقاف المراقبة
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
  }
  
  // التعامل مع تغير حالة الاتصال
  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    final isConnected = results.any((r) => 
      r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
    
    if (isConnected && _pendingOperations.isNotEmpty && !_isSyncing) {
      await syncPendingOperations();
    }
  }
  
  // إضافة عملية للتزامن لاحقاً
  Future<void> addPendingOperation({
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    _pendingOperations.add({
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _savePendingOperations();
  }
  
  // مزامنة العمليات المعلقة
  Future<Map<String, dynamic>> syncPendingOperations() async {
    if (_pendingOperations.isEmpty) {
      return {'synced': 0, 'failed': 0};
    }
    
    _isSyncing = true;
    int synced = 0;
    int failed = 0;
    
    // نسخة للعمليات الحالية
    final operations = List<Map<String, dynamic>>.from(_pendingOperations);
    
    for (final op in operations) {
      try {
        final success = await _executeOperation(op);
        if (success) {
          _pendingOperations.remove(op);
          synced++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
      }
    }
    
    await _savePendingOperations();
    _isSyncing = false;
    
    return {'synced': synced, 'failed': failed};
  }
  
  // تنفيذ عملية واحدة
  Future<bool> _executeOperation(Map<String, dynamic> op) async {
    final operation = op['operation'];
    final data = op['data'];
    
    switch (operation) {
      case 'add_student':
        // إرسال إلى API
        return true;
      case 'add_payment':
        // إرسال إلى API
        return true;
      case 'mark_attendance':
        // إرسال إلى API
        return true;
      default:
        return false;
    }
  }
  
  // حفظ العمليات المعلقة
  Future<void> _savePendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = _pendingOperations.map((op) => 
      '${op['operation']}|${op['timestamp']}|${op['data'].toString()}'
    ).join(';');
    await prefs.setString('pending_operations', jsonString);
  }
  
  // تحميل العمليات المعلقة
  Future<void> _loadPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('pending_operations');
    if (saved != null && saved.isNotEmpty) {
      // تحليل وتحميل العمليات
    }
  }
  
  // التحقق من الاتصال بالإنترنت
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
  }
  
  // تخزين محلي للبيانات (Cache)
  Future<void> cacheData() async {
    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseHelper.instance;
    
    final students = await db.getStudents();
    final groups = await db.getGroups();
    final payments = await db.getAllPayments();
    
    final cache = {
      'students': students.map((s) => s.toMap()).toList(),
      'groups': groups.map((g) => g.toMap()).toList(),
      'payments': payments.map((p) => p.toMap()).toList(),
      'cachedAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString('app_cache', jsonEncode(cache));
  }
  
  // استعادة البيانات من الكاش
  Future<Map<String, dynamic>> getCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('app_cache');
    if (cached != null) {
      return jsonDecode(cached);
    }
    return {};
  }
}

// إضافة import
import 'dart:convert';