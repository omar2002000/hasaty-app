// lib/screens/lock_screen.dart

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dashboard.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _message = "اضغط للمصادقة ببصمة الإصبع";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  _authenticate() async {
    setState(() {
      _loading = true;
      _message = "جارٍ التحقق...";
    });
    try {
      final bool canAuth = await auth.canCheckBiometrics;
      if (!canAuth) {
        setState(() {
          _message = "البصمة غير متاحة على هذا الجهاز";
          _loading = false;
        });
        return;
      }
      final bool didAuth = await auth.authenticate(
        localizedReason: 'للوصول إلى تطبيق حصتي',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      if (didAuth && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      } else {
        setState(() {
          _message = "فشل التحقق — حاول مجدداً";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = "خطأ في البصمة — اضغط للمحاولة";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              "تطبيق حصتي",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              "مستر نصر علي",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : GestureDetector(
                    onTap: _authenticate,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.fingerprint, size: 60, color: Colors.white),
                    ),
                  ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}