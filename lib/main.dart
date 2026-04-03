import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/students_screen.dart';
import 'screens/academic_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;
  runApp(HasatyApp(isDark: isDark));
}

class HasatyApp extends StatefulWidget {
  final bool isDark;
  const HasatyApp({required this.isDark});

  static _HasatyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_HasatyAppState>();

  @override
  _HasatyAppState createState() => _HasatyAppState();
}

class _HasatyAppState extends State<HasatyApp> {
  late bool _isDark;

  @override
  void initState() { super.initState(); _isDark = widget.isDark; }

  void toggleTheme(bool val) async {
    setState(() => _isDark = val);
    (await SharedPreferences.getInstance()).setBool('darkMode', val);
  }

  bool get isDark => _isDark;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'حصتي',
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
    home: const MainScreen(),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen();
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    StudentsScreen(),
    AcademicScreen(),
    SubscriptionScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined),        activeIcon: Icon(Icons.home),         label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outlined),       activeIcon: Icon(Icons.people),        label: 'الطلاب'),
            BottomNavigationBarItem(icon: Icon(Icons.school_outlined),       activeIcon: Icon(Icons.school),        label: 'التقييم'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long),  label: 'الاشتراكات'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined),    activeIcon: Icon(Icons.analytics),     label: 'التقارير'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined),     activeIcon: Icon(Icons.settings),      label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }
}
