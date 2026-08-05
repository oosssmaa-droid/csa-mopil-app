import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/department.dart';
import '../theme.dart';

class ResultScreen extends StatelessWidget {
  final String userName;
  final Department dept;
  final int score;
  final bool pass;
  final int attemptNum;
  final String newStatus;
  final List<String> weakControls;

  ResultScreen({
    super.key,
    required this.userName,
    required this.dept,
    required this.score,
    required this.pass,
    required this.attemptNum,
    required this.newStatus,
    required this.weakControls,
  });

  @override
  Widget build(BuildContext context) {
    final cc = csaColors(context);
    final color = pass ? cc.accent2 : cc.danger;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(S.t('resultTitle')),
      ),
      body: Padding(
        padding: EdgeInsets.all(18),
        child: ListView(
          children: [
            Center(
              child: Container(
                width: 140,
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 8),
                ),
                child: Text('$score%',
                    style: TextStyle(
                        color: color,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 14),
            Center(
              child: Text(
                  '${S.t('required')}: ${dept.threshold}% · ${S.t('attempt')} $attemptNum/3',
                  style: TextStyle(color: cc.muted)),
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                pass
                    ? S.t('passMsg')
                    : (newStatus == 'blocked'
                        ? S.t('blockedMsg')
                        : S.t('failMsg')),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
            if (!pass && newStatus != 'blocked')
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Center(
                  child: Text(
                      '${S.t('attemptsLeft')}: ${3 - attemptNum}',
                      style: TextStyle(color: cc.muted)),
                ),
              ),
            if (!pass && weakControls.isNotEmpty)
              Card(
                margin: EdgeInsets.only(top: 16),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.t('weakControls'),
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      ...weakControls.map((w) => Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('• $w',
                                style: TextStyle(
                                    fontSize: 12, color: cc.muted)),
                          )),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .popUntil(ModalRoute.withName('/home')),
              child: Text(S.t('backHome')),
            ),
          ],
        ),
      ),
    );
  }
}
