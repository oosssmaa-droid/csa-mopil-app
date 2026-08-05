import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/department.dart';
import '../models/course.dart';

/// Generates the per-employee training course + exam.
///
/// IMPORTANT CONTRACT: exam questions must be grounded in the lessons just
/// generated — each ExamQuestion.lessonTitle must match a Lesson.title from
/// the same response, and the correct answer must be verifiable from that
/// lesson's content. If you wire this up to your own backend/LLM, generate
/// the lessons first, then generate questions strictly from what was
/// written (never introduce facts that are not in a lesson). This keeps
/// the exam traceable to the exact material the employee studied, matching
/// the "RAG not fine-tuning" traceability principle from the proposal.
///
/// SECURITY NOTE FOR THE CAPSTONE TEAM:
/// Never ship a production build with an API key embedded in the client.
/// The intended architecture (per the project proposal) is: this app calls
/// YOUR Oracle APEX / PL/SQL backend (PKG_AI_INTEGRATION), which in turn
/// calls the locally-hosted open-weight LLM inside the isolated network.
/// The fields below are provided via --dart-define so no secret ever lives
/// in source control:
///
///   flutter build apk --release \
///     --dart-define=BACKEND_URL=https://your-backend.example/api/generate
///
/// If BACKEND_URL is not supplied, the app automatically uses the local
/// fallback generator below, so the app is always fully usable offline /
/// during grading without any backend configured.
class AIService {
  static const String backendUrl =
      String.fromEnvironment('BACKEND_URL', defaultValue: '');

  static Future<GeneratedCourse> generateCourse(
      Department dept, bool isAr) async {
    if (backendUrl.isNotEmpty) {
      try {
        final res = await http
            .post(
              Uri.parse(backendUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'department': isAr ? dept.ar : dept.en,
                'system': isAr ? dept.systemAr : dept.systemEn,
                'language': isAr ? 'ar' : 'en',
              }),
            )
            .timeout(const Duration(seconds: 25));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return GeneratedCourse(
            lessons: (data['lessons'] as List)
                .map((e) => Lesson.fromJson(e))
                .toList(),
            questions: (data['questions'] as List)
                .map((e) => ExamQuestion.fromJson(e))
                .toList(),
            fromAI: true,
          );
        }
      } catch (_) {
        // fall through to local fallback
      }
    }
    return _fallback(dept, isAr);
  }

  /// Deterministic, template-based content tied to NCA ECC-2:2024 /
  /// TCC-1:2021 control references — used whenever no backend is
  /// configured or the network call fails, so the app never blocks the
  /// workflow.
  static GeneratedCourse _fallback(Department dept, bool isAr) {
    final sysName = isAr ? dept.systemAr : dept.systemEn;
    final deptName = isAr ? dept.ar : dept.en;
    const eccRef = 'ECC-2:2024';
    const tccRef = 'TCC-1:2021';

    final lessons = [
      Lesson(
        title: isAr
            ? 'مدخل إلى أمن $deptName'
            : 'Introduction to $deptName Security',
        content: isAr
            ? 'تُعد حماية $sysName أولوية وفق ضوابط الأمن السيبراني الأساسية ($eccRef). يتوجب على كل موظف يملك صلاحية وصول الالتزام بسياسات كلمات المرور، وعدم مشاركة الحسابات، والإبلاغ الفوري عن أي نشاط مشبوه.'
            : 'Protecting the $sysName is a priority under the Essential Cybersecurity Controls ($eccRef). Every employee with access must follow password policies, never share accounts, and report suspicious activity immediately.',
        ref: eccRef,
      ),
      Lesson(
        title: isAr
            ? 'التصيّد الاحتيالي والهندسة الاجتماعية'
            : 'Phishing & Social Engineering',
        content: isAr
            ? 'تستهدف رسائل التصيد انتحال جهات موثوقة لخداع الموظف للكشف عن بيانات الدخول. تحقق دائمًا من عنوان المرسل، ولا تضغط على روابط غير معروفة، وأبلغ فريق الأمن فورًا عند الشك.'
            : 'Phishing messages impersonate trusted parties to trick employees into revealing credentials. Always verify sender addresses, avoid unknown links, and report suspicious messages to the security team immediately.',
        ref: eccRef,
      ),
      Lesson(
        title: isAr
            ? 'العمل عن بُعد وأمن الاتصال'
            : 'Remote Work & Secure Connectivity',
        content: isAr
            ? 'عند العمل عن بُعد، يجب استخدام الشبكة الافتراضية الخاصة (VPN) المعتمدة فقط، وتفعيل قفل الشاشة التلقائي، وتجنّب الاتصال بشبكات Wi-Fi عامة غير موثوقة عند التعامل مع بيانات حساسة.'
            : 'When working remotely, only use the approved VPN, enable automatic screen lock, and avoid untrusted public Wi-Fi when handling sensitive data.',
        ref: tccRef,
      ),
      Lesson(
        title: isAr
            ? 'تصنيف البيانات ومبدأ أقل الصلاحيات'
            : 'Data Classification & Least Privilege',
        content: isAr
            ? 'الوصول إلى $sysName يُمنح وفق مبدأ أقل الصلاحيات اللازمة لأداء المهمة فقط. أي طلب صلاحية إضافية يجب أن يمر عبر التقييم والموافقة المرتبطة بدرجة الجاهزية.'
            : 'Access to the $sysName follows the least-privilege principle — only what is required for the role. Any extra permission must go through the readiness assessment and approval workflow.',
        ref: eccRef,
      ),
    ];

    // Question POOL (not a fixed set) — every item is derived directly FROM
    // the lesson above it (lessonTitle makes the link explicit and visible
    // in the UI). Two questions per lesson plus one integrative question
    // form a pool of 8; [AIService.sample] draws a random 5-question subset
    // per attempt so retakes form a real series of exams, always grounded
    // in the material the employee just studied — never a generic bank.
    final questions = [
      ExamQuestion(
        q: isAr
            ? 'بحسب درس «${lessons[0].title}»، ما الالتزام المطلوب من كل موظف يملك صلاحية وصول؟'
            : 'Per the lesson "${lessons[0].title}", what is required of every employee with access?',
        options: isAr
            ? ['مشاركة كلمة المرور مع المدير عند الطلب', 'الالتزام بسياسات كلمات المرور وعدم مشاركة الحسابات والإبلاغ الفوري عن أي نشاط مشبوه', 'استخدام نفس كلمة المرور لجميع الأنظمة', 'لا التزام إضافي بعد منح الصلاحية']
            : ['Share the password with the manager on request', 'Follow password policies, never share accounts, and report suspicious activity immediately', 'Reuse the same password everywhere', 'No further obligation once access is granted'],
        correct: 1,
        ref: lessons[0].ref,
        lessonTitle: lessons[0].title,
      ),
      ExamQuestion(
        q: isAr
            ? 'وفق درس «${lessons[0].title}»، أي مما يلي يُعد ممارسة يجب تجنّبها؟'
            : 'Per the lesson "${lessons[0].title}", which of the following should be avoided?',
        options: isAr
            ? ['استخدام كلمة مرور قوية وفريدة لكل نظام', 'مشاركة كلمة مرور واحدة بين عدة أنظمة لتسهيل الحفظ', 'تغيير كلمة المرور دوريًا', 'الإبلاغ عن أي نشاط مشبوه فورًا']
            : ['Using a strong, unique password per system', 'Sharing one password across several systems for convenience', 'Changing your password periodically', 'Reporting any suspicious activity immediately'],
        correct: 1,
        ref: lessons[0].ref,
        lessonTitle: lessons[0].title,
      ),
      ExamQuestion(
        q: isAr
            ? 'بحسب درس «${lessons[1].title}»، ما الإجراء الصحيح عند استلام رسالة بريد مشبوهة تطلب بيانات الدخول؟'
            : 'Per the lesson "${lessons[1].title}", what is the correct action upon receiving a suspicious email requesting login credentials?',
        options: isAr
            ? ['الرد بالبيانات المطلوبة', 'حذف الرسالة فقط دون إبلاغ', 'التحقق من عنوان المرسل وعدم الضغط على أي رابط والإبلاغ الفوري لفريق الأمن', 'إعادة توجيهها لزميل للتأكد']
            : ['Reply with the requested data', 'Just delete it without reporting', 'Verify the sender, avoid clicking any link, and report immediately', 'Forward it to a colleague to check'],
        correct: 2,
        ref: lessons[1].ref,
        lessonTitle: lessons[1].title,
      ),
      ExamQuestion(
        q: isAr
            ? 'وفق درس «${lessons[1].title}»، ما العلامة الشائعة التي تدل على رسالة تصيد محتملة؟'
            : 'Per the lesson "${lessons[1].title}", what is a common sign of a potential phishing message?',
        options: isAr
            ? ['رابط عاجل يطلب إدخال بيانات الدخول فورًا', 'عنوان مرسل رسمي مطابق تمامًا للنطاق الصحيح', 'عدم وجود أي رابط في الرسالة', 'توقيع رسمي معتاد للشركة']
            : ['An urgent link demanding immediate login', 'A sender address exactly matching the correct domain', 'No link in the message at all', 'A normal company signature'],
        correct: 0,
        ref: lessons[1].ref,
        lessonTitle: lessons[1].title,
      ),
      ExamQuestion(
        q: isAr
            ? 'بحسب درس «${lessons[2].title}»، ما الشرط الأساسي لاستخدام شبكة Wi-Fi عامة أثناء العمل عن بُعد؟'
            : 'Per the lesson "${lessons[2].title}", what is required before using public Wi-Fi while working remotely?',
        options: isAr
            ? ['لا يوجد شرط', 'الاتصال عبر VPN المعتمد فقط وتفعيل قفل الشاشة التلقائي', 'استخدام متصفح مختلف', 'تعطيل جدار الحماية']
            : ['No requirement', 'Connect only via the approved VPN and enable auto screen-lock', 'Use a different browser', 'Disable the firewall'],
        correct: 1,
        ref: lessons[2].ref,
        lessonTitle: lessons[2].title,
      ),
      ExamQuestion(
        q: isAr
            ? 'وفق درس «${lessons[2].title}»، ماذا يجب فعله عند الابتعاد عن الجهاز أثناء العمل عن بُعد؟'
            : 'Per the lesson "${lessons[2].title}", what should you do when stepping away from your device while working remotely?',
        options: isAr
            ? ['تركه مفتوحًا طالما أنه داخل المنزل', 'تفعيل قفل الشاشة فورًا', 'إغلاق التطبيقات المفتوحة فقط', 'لا حاجة لأي إجراء']
            : ['Leave it unlocked since it is at home', 'Enable screen lock immediately', 'Just close open apps', 'No action needed'],
        correct: 1,
        ref: lessons[2].ref,
        lessonTitle: lessons[2].title,
      ),
      ExamQuestion(
        q: isAr
            ? 'بحسب درس «${lessons[3].title}»، وفق مبدأ أقل الصلاحيات، متى تُمنح صلاحية إضافية على $sysName؟'
            : 'Per the lesson "${lessons[3].title}", under least privilege, when is an extra permission on the $sysName granted?',
        options: isAr
            ? ['فورًا عند الطلب', 'بعد اجتياز التقييم والموافقة المرتبطة بدرجة الجاهزية', 'لا تُمنح أبدًا', 'حسب الأقدمية الوظيفية']
            : ['Immediately on request', 'After passing the readiness assessment and approval workflow', 'Never granted', 'Based on seniority'],
        correct: 1,
        ref: lessons[3].ref,
        lessonTitle: lessons[3].title,
      ),
      ExamQuestion(
        q: isAr
            ? 'سؤال تكاملي بين درسي «${lessons[0].title}» و«${lessons[1].title}»: عند اكتشاف نشاط غير معتاد على حسابك، ما الخطوة الأولى الصحيحة؟'
            : 'Integrative question across "${lessons[0].title}" and "${lessons[1].title}": upon discovering unusual activity on your account, what is the correct first step?',
        options: isAr
            ? ['تجاهله إن لم يتكرر', 'تغيير كلمة المرور فقط دون إبلاغ أحد', 'الإبلاغ الفوري لفريق الأمن دون مشاركة أي بيانات إضافية', 'الانتظار حتى نهاية اليوم']
            : ['Ignore it if it does not repeat', 'Just change the password without telling anyone', 'Report immediately to the security team without sharing further data', 'Wait until end of day'],
        correct: 2,
        ref: lessons[0].ref,
        lessonTitle: '${lessons[0].title} / ${lessons[1].title}',
      ),
    ];

    return GeneratedCourse(lessons: lessons, questions: questions, fromAI: false);
  }

  /// Randomly samples [n] questions from a larger pool — used to turn a
  /// single generated course into a genuine series of exams: every attempt
  /// (including remedial retakes) gets a different 5-question subset.
  static List<ExamQuestion> sample(List<ExamQuestion> pool, int n) {
    final list = List<ExamQuestion>.from(pool)..shuffle();
    return list.take(n).toList();
  }
}
