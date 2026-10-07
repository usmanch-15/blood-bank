import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Cursor paging retains earlier pages; refresh deliberately starts a new snapshot.
class PagedRecords extends StatefulWidget {
  final Query<Map<String, dynamic>> query;
  final Widget Function(
    BuildContext,
    QueryDocumentSnapshot<Map<String, dynamic>>,
  )
  itemBuilder;
  final String emptyMessage;
  final bool shrinkWrap;
  const PagedRecords({
    super.key,
    required this.query,
    required this.itemBuilder,
    this.emptyMessage = 'No records yet.',
    this.shrinkWrap = false,
  });
  @override
  State<PagedRecords> createState() => _PagedRecordsState();
}

class _PagedRecordsState extends State<PagedRecords> {
  final _items = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  bool _loading = false, _more = true;
  String? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading && !refresh) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      if (refresh) {
        _items.clear();
        _more = true;
      }
    });
    try {
      var query = widget.query.limit(30);
      if (_items.isNotEmpty) query = query.startAfterDocument(_items.last);
      final page = await query.get();
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(page.docs);
        _more = page.docs.length == 30;
      });
    } catch (e) {
      if (mounted && generation == _generation)
        setState(
          () =>
              _error =
                  'Unable to load records. Check your connection and retry.',
        );
    } finally {
      if (mounted && generation == _generation)
        setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => _load(refresh: true),
    child: ListView(
      shrinkWrap: widget.shrinkWrap,
      physics:
          widget.shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _loading ? null : () => _load(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ),
        ..._items.map((d) => widget.itemBuilder(context, d)),
        if (_items.isEmpty && !_loading && _error == null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(widget.emptyMessage),
          ),
        if (_error != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
        if (!_loading && (_more || _error != null))
          TextButton(
            onPressed: _load,
            child: Text(_error != null ? 'Retry' : 'Load more'),
          ),
      ],
    ),
  );
}
