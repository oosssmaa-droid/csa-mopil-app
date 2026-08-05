import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/course.dart';
import '../models/department.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class _EmployeeSnapshot {
  final String name;
  final Map<String, String> status;
  final List<DecisionLogEntry> log;
  _EmployeeSnapshot(this.name, this.status, this.log);
}

class AdminScreen extends StatelessWidget {
  final String managerName;
  final List<Department> departments;
  final VoidCallback onToggleLang;
  final VoidCallback onToggleTheme;
  const AdminScreen({
    super.key,
    required this.managerName,
    required this.departments,
    required this.onToggleLang,
    required this.onToggleTheme,
  });

  Future<List<_EmployeeSnapshot>> _loadAll() async {
    final users = await StorageService.getAllUsers();
    final out = <_EmployeeSnapshot>[];
    for (final u in users) {
      final status = await StorageService.getStatus(u);
      final log = await StorageService.getLog(u);
      out.add(_EmployeeSnapshot(u, status, log));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cc = csaColors(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(S.t('adminTitle')),
        actions: csaTopActions(
          context,
          onToggleTheme: onToggleTheme,
          onToggleLang: onToggleLang,
          isAr: S.isAr,
          onLogout: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
      body: FutureBuilder<List<_EmployeeSnapshot>>(
        future: _loadAll(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;

          int totalApproved = 0, totalBlocked = 0, totalPending = 0;
          final perDept = <String, Map<String, int>>{};
          for (final d in departments) {
            perDept[d.key] = {'approved': 0, 'blocked': 0, 'pending': 0, 'none': 0};
          }
          final combinedLog = <MapEntry<String, DecisionLogEntry>>[];

          for (final emp in all) {
            for (final d in departments) {
              final st = emp.status[d.key];
              final bucket = perDept[d.key]!;
              if (st == null || st == 'none') {
                bucket['none'] = bucket['none']! + 1;
                continue;
              }
              if (st == 'approved') {
                bucket['approved'] = bucket['approved']! + 1;
                totalApproved++;
              } else if (st == 'blocked') {
                bucket['blocked'] = bucket['blocked']! + 1;
                totalBlocked++;
              } else {
                bucket['pending'] = bucket['pending']! + 1;
                totalPending++;
              }
            }
            for (final l in emp.log) {
              combinedLog.add(MapEntry(emp.name, l));
            }
          }
          combinedLog.sort((a, b) => b.value.date.compareTo(a.value.date));

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(managerName, style: TextStyle(color: cc.muted)),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _statCard(cc, '${all.length}', S.t('totalEmployees'), cc.text),
                      _statCard(cc, '$totalApproved', S.t('totalApproved'), cc.accent2),
                      _statCard(cc, '$totalBlocked', S.t('totalBlocked'), cc.danger),
                      _statCard(cc, '$totalPending', S.t('totalPending'), cc.warn),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.t('byDept'),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...departments.map((d) {
                        final p = perDept[d.key]!;
                        final tot = (p['approved']! +
                                p['blocked']! +
                                p['pending']! +
                                p['none']!)
                            .clamp(1, 1 << 30);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(d.name(S.isAr),
                                      style: const TextStyle(fontSize: 12)),
                                  Text(
                                      '${p['approved']! + p['blocked']! + p['pending']!}/$tot',
                                      style: TextStyle(
                                          fontSize: 11, color: cc.muted)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  height: 8,
                                  child: Row(
                                    children: [
                                      if (p['approved']! > 0)
                                        _seg(p['approved']!, cc.accent2),
                                      if (p['pending']! > 0)
                                        _seg(p['pending']!, cc.warn),
                                      if (p['blocked']! > 0)
                                        _seg(p['blocked']!, cc.danger),
                                      if (p['none']! > 0)
                                        _seg(p['none']!, cc.border),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Wrap(spacing: 12, runSpacing: 6, children: [
                        _legend(cc.accent2, S.t('approved')),
                        _legend(cc.warn, S.t('totalPending')),
                        _legend(cc.danger, S.t('blocked')),
                        _legend(cc.border, S.t('notReq')),
                      ]),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.t('orgLog'),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (combinedLog.isEmpty)
                        Text(S.t('noData'), style: TextStyle(color: cc.muted))
                      else
                        ...combinedLog.take(60).map((e) {
                          final l = e.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                                border:
                                    Border(top: BorderSide(color: cc.border))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('${e.key} · ${l.systemName}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (l.result == 'approved'
                                                ? cc.accent2
                                                : cc.danger)
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(l.result,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: l.result == 'approved'
                                                  ? cc.accent2
                                                  : cc.danger)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                    '${l.score}%/${l.threshold}% · ${S.t('attempt')} ${l.attempt} · ${l.date.toLocal().toString().split(".").first}',
                                    style: TextStyle(
                                        fontSize: 10, color: cc.muted)),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _seg(int value, Color color) =>
      Expanded(flex: value, child: Container(color: color));

  Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  Widget _statCard(CSAColors cc, String value, String label, Color valueColor) =>
      Container(
        decoration:
            BoxDecoration(color: cc.card2, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: cc.muted),
                textAlign: TextAlign.center),
          ],
        ),
      );
}
