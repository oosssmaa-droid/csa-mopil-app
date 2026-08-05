import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/department.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  final List<Department> departments;
  final VoidCallback onToggleLang;
  final VoidCallback onToggleTheme;
  const LoginScreen({
    super.key,
    required this.departments,
    required this.onToggleLang,
    required this.onToggleTheme,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final nameCtrl = TextEditingController();
  Department? selected;
  String role = 'employee'; // employee | manager

  @override
  void initState() {
    super.initState();
    nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    if (role == 'manager') {
      Navigator.of(context).push(MaterialPageRoute(
        settings: const RouteSettings(name: '/home'),
        builder: (_) => AdminScreen(
          managerName: name,
          departments: widget.departments,
          onToggleLang: widget.onToggleLang,
          onToggleTheme: widget.onToggleTheme,
        ),
      ));
      return;
    }
    if (selected == null) return;
    await StorageService.registerUser(name);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: '/home'),
      builder: (_) => HomeScreen(
        userName: name,
        dept: selected!,
        onToggleLang: widget.onToggleLang,
        onToggleTheme: widget.onToggleTheme,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cc = csaColors(context);
    final isMgr = role == 'manager';
    final canEnter = nameCtrl.text.trim().isNotEmpty && (isMgr || selected != null);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cc.accent, cc.accent2]),
                borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: const Text('🛡️'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(S.t('brand'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text(S.t('brandSub'),
                    style: TextStyle(fontSize: 10, color: cc.muted)),
              ],
            ),
          ),
        ]),
        actions: csaTopActions(
          context,
          onToggleTheme: widget.onToggleTheme,
          onToggleLang: () {
            widget.onToggleLang();
            setState(() {});
          },
          isAr: S.isAr,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(S.t('loginTitle'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                    'KAUST Cybersecurity Summer Enrichment 2026 — Capstone',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              !isMgr ? cc.accent.withOpacity(0.12) : null,
                          side: BorderSide(
                              color: !isMgr ? cc.accent : cc.border),
                        ),
                        onPressed: () => setState(() => role = 'employee'),
                        child: Text(S.t('asEmployee'),
                            style: TextStyle(
                                fontSize: 12,
                                color: !isMgr ? cc.accent : cc.text)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              isMgr ? cc.accent.withOpacity(0.12) : null,
                          side:
                              BorderSide(color: isMgr ? cc.accent : cc.border),
                        ),
                        onPressed: () => setState(() => role = 'manager'),
                        child: Text(S.t('asManager'),
                            style: TextStyle(
                                fontSize: 12,
                                color: isMgr ? cc.accent : cc.text)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                      hintText: isMgr ? S.t('managerName') : S.t('name')),
                ),
                if (!isMgr) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Department>(
                    value: selected,
                    decoration: InputDecoration(hintText: S.t('chooseDept')),
                    items: widget.departments
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.name(S.isAr)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canEnter ? _enter : null,
                    child: Text(S.t('enter')),
                  ),
                ),
                if (isMgr)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(S.t('managerNote'),
                        style: TextStyle(fontSize: 11, color: cc.muted)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
