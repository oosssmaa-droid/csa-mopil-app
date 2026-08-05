class Lesson {
  final String title;
  final String content;
  final String ref;
  Lesson({required this.title, required this.content, required this.ref});

  factory Lesson.fromJson(Map<String, dynamic> j) =>
      Lesson(title: j['title'], content: j['content'], ref: j['ref']);
}

class ExamQuestion {
  final String q;
  final List<String> options;
  final int correct;
  final String ref;
  final String lessonTitle;
  ExamQuestion(
      {required this.q,
      required this.options,
      required this.correct,
      required this.ref,
      required this.lessonTitle});

  factory ExamQuestion.fromJson(Map<String, dynamic> j) => ExamQuestion(
        q: j['q'],
        options: List<String>.from(j['options']),
        correct: j['correct'],
        ref: j['ref'],
        lessonTitle: j['lessonTitle'] ?? '',
      );
}

class GeneratedCourse {
  final List<Lesson> lessons;
  final List<ExamQuestion> questions;
  final bool fromAI;
  GeneratedCourse(
      {required this.lessons, required this.questions, required this.fromAI});
}

/// Immutable log entry — written once per exam attempt, never edited.
/// Mirrors the platform's compliance requirement (NCA ECC / ISO 27001 / NIST
/// CSF 2.0 audit evidence) described in the project proposal.
class DecisionLogEntry {
  final DateTime date;
  final String deptKey;
  final String systemName;
  final int score;
  final int threshold;
  final int attempt;
  final String result; // approved | remedial | blocked
  final List<String> weakControls;

  DecisionLogEntry({
    required this.date,
    required this.deptKey,
    required this.systemName,
    required this.score,
    required this.threshold,
    required this.attempt,
    required this.result,
    required this.weakControls,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'deptKey': deptKey,
        'systemName': systemName,
        'score': score,
        'threshold': threshold,
        'attempt': attempt,
        'result': result,
        'weakControls': weakControls,
      };

  factory DecisionLogEntry.fromJson(Map<String, dynamic> j) =>
      DecisionLogEntry(
        date: DateTime.parse(j['date']),
        deptKey: j['deptKey'],
        systemName: j['systemName'],
        score: j['score'],
        threshold: j['threshold'],
        attempt: j['attempt'],
        result: j['result'],
        weakControls: List<String>.from(j['weakControls'] ?? []),
      );
}
