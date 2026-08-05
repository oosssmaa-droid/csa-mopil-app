import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/department.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'course_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final Department dept;
  final VoidCallback onToggleLang;
  final VoidCallback onToggleTheme;
  const HomeScreen({
    super.key,
    required this.userName,
    required this.dept,
    required this.onToggleLang,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String status = 'none';
  bool loading = true;
  late CSAColors cc;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = await StorageService.getStatus(widget.userName);
    setState(() {
      status = map[widget.dept.key] ?? 'none';
      loading = false;
    });
  }

  String _statusLabel(String st) {
    switch (st) {
      case 'training':
        return S.t('pendingTrain');
      case 'examReady':
        return S.t('pendingExam');
      case 'approved':
        return S.t('approved');
      case 'blocked':
        return S.t('blocked');
      case 'remedial':
        return S.t('remedial');
      default:
        return S.t('notReq');
    }
  }

  Widget _levelPill(String level) {
    final map = {
      'crit': [cc.danger, S.t('crit')],
      'high': [cc.warn, S.t('high')],
      'med': [cc.accent, S.t('med')],
    };
    final entry = map[level]!;
    final color = entry[0] as Color;
    final label = entry[1] as String;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionButton() {
    switch (status) {
      case 'none':
        return _primaryBtn(S.t('request'), _startRequest);
      case 'training':
        return _primaryBtn(S.t('continueTraining'), _goCourse);
      case 'examReady':
        return _primaryBtn(S.t('startExam'), _goCourse);
      case 'remedial':
        return _primaryBtn(S.t('continueTraining'), _startRequest);
      case 'approved':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: cc.accent2.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Text('✓ ${S.t('approved')}',
              style: TextStyle(color: cc.accent2, fontWeight: FontWeight.bold)),
        );
      case 'blocked':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: cc.danger.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Text(S.t('blocked'),
              style: TextStyle(color: cc.danger, fontWeight: FontWeight.bold)),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _primaryBtn(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(onPressed: onTap, child: Text(label)),
      );

  Future<void> _startRequest() async {
    await StorageService.setStatus(widget.userName, widget.dept.key, 'training');
    if (!mounted) return;
    _goCourse();
  }

  void _goCourse() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => CourseScreen(
            userName: widget.userName,
            dept: widget.dept,
            onToggleLang: widget.onToggleLang,
            onToggleTheme: widget.onToggleTheme,
          ),
        ))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    cc = csaColors(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(S.t('homeTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DashboardScreen(
                      userName: widget.userName,
                      dept: widget.dept,
                      onToggleLang: widget.onToggleLang,
                      onToggleTheme: widget.onToggleTheme,
                    ))),
          ),
          ...csaTopActions(
            context,
            onToggleTheme: widget.onToggleTheme,
            onToggleLang: () {
              widget.onToggleLang();
              setState(() {});
            },
            isAr: S.isAr,
            onLogout: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.userName} · ${widget.dept.name(S.isAr)}',
                      style: TextStyle(color: cc.muted)),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.dept.systemName(S.isAr),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_statusLabel(status),
                              style: TextStyle(fontSize: 12, color: cc.muted)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, children: [
                            _levelPill(widget.dept.level),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                  color: cc.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                  '${S.t('threshold')}: ${widget.dept.threshold}%',
                                  style: TextStyle(
                                      color: cc.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          _actionButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
