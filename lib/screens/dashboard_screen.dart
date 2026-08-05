import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/strings.dart';
import '../models/course.dart';
import '../models/department.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class DashboardScreen extends StatelessWidget {
  final String userName;
  final Department dept;
  final VoidCallback onToggleLang;
  final VoidCallback onToggleTheme;
  const DashboardScreen({
    super.key,
    required this.userName,
    required this.dept,
    required this.onToggleLang,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final cc = csaColors(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(S.t('dashboard')),
        actions: csaTopActions(
          context,
          onToggleTheme: onToggleTheme,
          onToggleLang: onToggleLang,
          isAr: S.isAr,
          onLogout: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([
          StorageService.getLog(userName),
          StorageService.getStatus(userName),
          StorageService.getAttempts(userName, dept.key),
        ]),
        builder: (context, AsyncSnapshot<List<Object>> snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final log = snap.data![0] as List<DecisionLogEntry>;
          final status = snap.data![1] as Map<String, String>;
          final attemptsUsed = snap.data![2] as int;
          final st = status[dept.key] ?? 'none';
          final lastScore = log.isNotEmpty ? '${log.first.score}%' : '—';
          final statusLabels = {
            'none': S.t('notReq'),
            'training': S.t('pendingTrain'),
            'examReady': S.t('pendingExam'),
            'approved': S.t('approved'),
            'blocked': S.t('blocked'),
            'remedial': S.t('remedial'),
          };

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text('$userName · ${dept.name(S.isAr)}',
                  style: TextStyle(color: cc.muted)),
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
                      _statCard(cc, statusLabels[st] ?? st, S.t('yourStatus')),
                      _statCard(cc, lastScore, S.t('lastScore')),
                      _statCard(cc, '$attemptsUsed/3', S.t('attemptsUsed')),
                      _statCard(cc, '${dept.threshold}%', S.t('threshold')),
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
                      Text(S.t('log'),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (log.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child:
                              Text(S.t('noData'), style: TextStyle(color: cc.muted)),
                        ),
                      ...log.map((l) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: cc.border))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(l.systemName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (l.result == 'approved'
                                                ? cc.accent2
                                                : cc.danger)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        l.result,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: l.result == 'approved'
                                              ? cc.accent2
                                              : cc.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat.yMd().add_Hm().format(l.date)} · ${S.t('yourScore')}: ${l.score}%/${l.threshold}% · ${S.t('attempt')} ${l.attempt}',
                                  style: TextStyle(fontSize: 11, color: cc.muted),
                                ),
                              ],
                            ),
                          )),
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

  Widget _statCard(CSAColors cc, String value, String label) => Container(
        decoration: BoxDecoration(
            color: cc.card2, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: cc.muted),
                textAlign: TextAlign.center),
          ],
        ),
      );
}
