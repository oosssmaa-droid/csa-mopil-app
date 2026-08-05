import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/department.dart';
import '../models/course.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'exam_screen.dart';

class CourseScreen extends StatefulWidget {
  final String userName;
  final Department dept;
  final VoidCallback onToggleLang;
  final VoidCallback onToggleTheme;
  const CourseScreen({
    super.key,
    required this.userName,
    required this.dept,
    required this.onToggleLang,
    required this.onToggleTheme,
  });

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  GeneratedCourse? course;
  int idx = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await AIService.generateCourse(widget.dept, S.isAr);
    if (!mounted) return;
    setState(() => course = c);
  }

  void _goExam() {
    final sampled = AIService.sample(course!.questions, 5);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExamScreen(
        userName: widget.userName,
        dept: widget.dept,
        questions: sampled,
        onToggleLang: widget.onToggleLang,
        onToggleTheme: widget.onToggleTheme,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cc = csaColors(context);

    if (course == null) {
      final msgs = [S.t('genLoading1'), S.t('genLoading2'), S.t('genLoading3')];
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(msgs[0],
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cc.muted)),
              ),
            ],
          ),
        ),
      );
    }

    final lesson = course!.lessons[idx];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            '${S.t('lessonOf')} ${idx + 1} ${S.t('of')} ${course!.lessons.length}'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(course!.lessons.length, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= idx ? cc.accent2 : cc.card2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
            if (!course!.fromAI)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(S.t('apiFallback'),
                    style: TextStyle(color: cc.warn, fontSize: 11)),
              ),
            const SizedBox(height: 14),
            Text(lesson.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(lesson.content,
                    style: const TextStyle(fontSize: 14, height: 1.9)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: cc.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('${S.t('ref')}: ${lesson.ref}',
                  style: TextStyle(color: cc.accent, fontSize: 11)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (idx > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => idx--),
                      child: Text(S.t('prev')),
                    ),
                  ),
                if (idx > 0) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: idx < course!.lessons.length - 1
                        ? () => setState(() => idx++)
                        : _goExam,
                    child: Text(idx < course!.lessons.length - 1
                        ? S.t('next')
                        : S.t('finishLessons')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
