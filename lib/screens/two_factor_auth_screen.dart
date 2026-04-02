import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/activity_log_service.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  final VoidCallback? onVerified;
  const TwoFactorAuthScreen({super.key, this.onVerified});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _verificationCode = '';
  bool _isLoading = false;
  bool _isEnabled = false;
  String _teacherPhone = '01000000000'; // رقم المعلم

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnabled = prefs.getBool('two_factor_enabled') ?? false;
    });
  }

  Future<void> _sendVerificationCode() async {
    setState(() => _isLoading = true);

    // توليد رمز عشوائي مكون من 6 أرقام
    _verificationCode = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();

    // إرسال عبر واتساب
    final formattedPhone = _teacherPhone.startsWith('0')
        ? _teacherPhone.substring(1)
        : _teacherPhone;
    final message = 'رمز التحقق الخاص بتطبيق حصتي هو: $_verificationCode\n\nهذا الرمز صالح لمدة 5 دقائق';
    final url = "https://wa.me/20$formattedPhone?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }

    setState(() => _isLoading = false);

    // عرض مربع إدخال الرمز
    _showVerificationDialog();
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('تحقق من هويتك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تم إرسال رمز التحقق إلى واتساب'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'أدخل الرمز',
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => _verifyCode(ctx),
            child: const Text('تحقق'),
          ),
        ],
      ),
    );
  }

  void _verifyCode(BuildContext ctx) {
    final enteredCode = _codeController.text.trim();

    if (enteredCode == _verificationCode) {
      _enableTwoFactor();
      Navigator.pop(ctx);
      widget.onVerified?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تفعيل التحقق بخطوتين بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ الرمز غير صحيح، حاول مرة أخرى'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _enableTwoFactor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('two_factor_enabled', true);

    await ActivityLogService().log(
      action: 'two_factor_enabled',
      userName: 'مستر نصر علي',
      details: {'timestamp': DateTime.now().toIso8601String()},
    );

    setState(() => _isEnabled = true);
  }

  Future<void> _disableTwoFactor() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعطيل التحقق بخطوتين'),
        content: const Text('هل أنت متأكد من تعطيل التحقق بخطوتين؟ سيصبح دخول التطبيق أقل أماناً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تعطيل'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('two_factor_enabled', false);

      await ActivityLogService().log(
        action: 'two_factor_disabled',
        userName: 'مستر نصر علي',
      );

      setState(() => _isEnabled = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تعطيل التحقق بخطوتين'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق بخطوتين'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEnabled ? Icons.shield : Icons.shield_outlined,
                    color: _isEnabled ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEnabled ? 'مفعل' : 'غير مفعل',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isEnabled ? Colors.green : Colors.grey,
                          ),
                        ),
                        Text(
                          _isEnabled
                              ? 'التطبيق محمي بالتحقق بخطوتين'
                              : 'قم بتفعيل التحقق بخطوتين لزيادة أمان التطبيق',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'كيف يعمل التحقق بخطوتين؟',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _infoItem(
              '1',
              'عند فتح التطبيق، سيطلب منك إدخال رمز التحقق',
              Icons.lock_open,
            ),
            _infoItem(
              '2',
              'سيتم إرسال رمز عبر واتساب إلى رقم هاتفك',
              Icons.whatsapp,
            ),
            _infoItem(
              '3',
              'أدخل الرمز للتحقق من هويتك والدخول للتطبيق',
              Icons.verified,
            ),
            const SizedBox(height: 24),
            if (!_isEnabled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendVerificationCode,
                  icon: const Icon(Icons.security),
                  label: const Text('تفعيل التحقق بخطوتين'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _disableTwoFactor,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('تعطيل التحقق بخطوتين'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'ملاحظة: تأكد من صحة رقم هاتفك في الإعدادات لاستلام رمز التحقق',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}