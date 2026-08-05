import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/strings.dart';
import 'models/department.dart';
import 'screens/login_screen.dart';
import 'services/storage_service.dart';
import 'theme.dart';

void main() {
  runApp(const CSAApp());
}

class CSAApp extends StatefulWidget {
  const CSAApp({super.key});

  @override
  State<CSAApp> createState() => _CSAAppState();
}

class _CSAAppState extends State<CSAApp> {
  List<Department> departments = [];
  bool loaded = false;
  bool isDark = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final raw = await rootBundle.loadString('assets/data/departments.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Department.fromJson(e))
        .toList();
    final savedTheme = await StorageService.getTheme();
    setState(() {
      departments = list;
      isDark = savedTheme != 'light';
      loaded = true;
    });
  }

  void _toggleLang() {
    setState(() {
      S.isAr = !S.isAr;
    });
  }

  Future<void> _toggleTheme() async {
    setState(() => isDark = !isDark);
    await StorageService.setTheme(isDark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CSA Platform',
      theme: buildAppTheme(isDark),
      locale: Locale(S.isAr ? 'ar' : 'en'),
      builder: (context, child) => Directionality(
        textDirection: S.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      home: !loaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : LoginScreen(
              departments: departments,
              onToggleLang: _toggleLang,
              onToggleTheme: _toggleTheme,
            ),
    );
  }
}
