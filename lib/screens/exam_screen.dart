import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/department.dart';
import '../models/course.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'result_screen.dart';

class ExamScreen extends StatefulWidget {
  final String userName;
  final Department dept;
  final List<ExamQuestion> questions;
  final VoidCallback onToggleLang;
  final VoidCallback onToggleTheme;
  const ExamScreen({
    super.key,
    required this.userName,
    required this.dept,
    required this.questions,
    required this.onToggleLang,
    required this.onToggleTheme,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final Map<int, int> answers = {};

  Future<void> _submit() async {
    if (answers.length < widget.questions.length) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.t('selectAnswer'))));
      return;
    }
    int correct = 0;
    final weak = <String>[];
    for (var i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      if (answers[i] == q.correct) {
        correct++;
      } else {
        weak.add('${q.ref}: ${q.q}');
      }
    }
    final score = ((correct / widget.questions.length) * 100).round();
    final pass = score >= widget.dept.threshold;
    final attemptNum =
        await StorageService.incrementAttempts(widget.userName, widget.dept.key);

    String newStatus;
    if (pass) {
      newStatus = 'approved';
    } else if (attemptNum >= 3) {
      newStatus = 'blocked';
    } else {
      newStatus = 'remedial';
    }
    await StorageService.setStatus(widget.userName, widget.dept.key, newStatus);
    await StorageService.appendLog(
      widget.userName,
      DecisionLogEntry(
        date: DateTime.now(),
        deptKey: widget.dept.key,
        systemName: widget.dept.systemName(S.isAr),
        score: score,
        threshold: widget.dept.threshold,
        attempt: attemptNum,
        result: newStatus == 'approved'
            ? 'approved'
            : (newStatus == 'blocked' ? 'blocked' : 'remedial'),
        weakControls: weak,
      ),
    );

    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultScreen(
        userName: widget.userName,
        dept: widget.dept,
        score: score,
        pass: pass,
        attemptNum: attemptNum,
        newStatus: newStatus,
        weakControls: weak,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cc = csaColors(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(S.t('examTitle')),
        automaticallyImplyLeading: false,
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
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
              '${widget.dept.name(S.isAr)} · ${S.t('threshold')} ${widget.dept.threshold}%',
              style: TextStyle(color: cc.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(S.t('examSeriesNote'),
              style: TextStyle(color: cc.muted, fontSize: 11)),
          const SizedBox(height: 12),
          ...List.generate(widget.questions.length, (qi) {
            final q = widget.questions[qi];
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (q.lessonTitle.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: cc.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('${S.t('basedOnLesson')}: ${q.lessonTitle}',
                            style: TextStyle(color: cc.accent, fontSize: 11)),
                      ),
                    Text('${S.t('question')} ${qi + 1}. ${q.q}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    ...List.generate(q.options.length, (oi) {
                      final selected = answers[qi] == oi;
                      return GestureDetector(
                        onTap: () => setState(() => answers[qi] = oi),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: selected ? cc.accent : cc.border),
                            borderRadius: BorderRadius.circular(12),
                            color: selected
                                ? cc.accent.withOpacity(0.08)
                                : null,
                          ),
                          child: Text(q.options[oi],
                              style: const TextStyle(fontSize: 13)),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          ElevatedButton(onPressed: _submit, child: Text(S.t('submitExam'))),
        ],
      ),
    );
  }
}
