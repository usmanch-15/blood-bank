class AwarenessBanner {
  final String id, imageUrl, action;
  final int revision;
  final Map<String, dynamic> en, ur;
  AwarenessBanner.fromMap(Map<String, dynamic> d)
    : id = d['id'] as String,
      imageUrl = d['imageUrl'] as String? ?? '',
      action = d['action'] as String? ?? 'requests',
      revision = (d['revision'] as num?)?.toInt() ?? 0,
      en = Map<String, dynamic>.from(d['en'] as Map? ?? {}),
      ur = Map<String, dynamic>.from(d['ur'] as Map? ?? {});
  String text(String key, bool isUrdu) =>
      ((isUrdu ? ur[key] : en[key]) ?? en[key] ?? '').toString();
  String get dismissalKey => '$id:$revision';
}
