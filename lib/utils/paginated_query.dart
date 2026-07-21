import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic Firestore pagination helper.
///
/// Ye class pehle se `admin_web_donations.dart` mein use ho rahi thi lekin
/// project mein kahin define nahi thi (isliye "Undefined class" error aa
/// raha tha) — ye is project ka purana/incomplete hissa tha, meri taraf se
/// nahi aaya. Ab poori tarah implement kar di hai.
class PaginatedQuery<T> {
  final int pageSize;
  final Query<Map<String, dynamic>> Function() queryBuilder;
  final T Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) fromDoc;

  PaginatedQuery({
    required this.pageSize,
    required this.queryBuilder,
    required this.fromDoc,
  });

  final List<T> items = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _hasMore = true;
  bool isLoading = false;
  Object? error;

  bool get hasMore => _hasMore;

  Future<void> loadNextPage() async {
    if (isLoading || !_hasMore) return;
    isLoading = true;
    error = null;
    try {
      Query<Map<String, dynamic>> query = queryBuilder().limit(pageSize);
      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        items.addAll(snapshot.docs.map(fromDoc));
      }
      _hasMore = snapshot.docs.length == pageSize;
    } catch (e) {
      error = e;
    } finally {
      isLoading = false;
    }
  }

  /// Sab kuch reset karke pehle page se dobara load karna.
  void reset() {
    items.clear();
    _lastDoc = null;
    _hasMore = true;
    error = null;
  }
}