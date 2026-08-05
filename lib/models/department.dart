class Department {
  final String key;
  final String ar;
  final String en;
  final int threshold;
  final String level; // crit | high | med
  final String systemAr;
  final String systemEn;

  Department({
    required this.key,
    required this.ar,
    required this.en,
    required this.threshold,
    required this.level,
    required this.systemAr,
    required this.systemEn,
  });

  factory Department.fromJson(Map<String, dynamic> j) => Department(
        key: j['key'],
        ar: j['ar'],
        en: j['en'],
        threshold: j['threshold'],
        level: j['level'],
        systemAr: j['systemAr'],
        systemEn: j['systemEn'],
      );

  String name(bool isAr) => isAr ? ar : en;
  String systemName(bool isAr) => isAr ? systemAr : systemEn;
}
