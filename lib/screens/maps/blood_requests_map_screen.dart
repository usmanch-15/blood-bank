import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/workflow_service.dart';
import '../requests/request_tracking_screen.dart';
import '../../l10n/app_localizations.dart';

class BloodRequestsMapScreen extends StatefulWidget {
  const BloodRequestsMapScreen({super.key});
  @override
  State<BloodRequestsMapScreen> createState() => _BloodRequestsMapScreenState();
}

class _BloodRequestsMapScreenState extends State<BloodRequestsMapScreen> {
  final _map = MapController();
  final _requests = <Map<String, dynamic>>[];
  String? _error;
  bool _loading = true;
  double _radius = 5;
  String? _cursor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await WorkflowService.call('discoverRequests', {
        'radiusKm': _radius,
        if (more) 'cursor': _cursor,
      });
      final items =
          (page['items'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .where((e) => e['latitude'] is num && e['longitude'] is num)
              .toList();
      if (mounted) {
        setState(() {
          if (!more) _requests.clear();
          _requests.addAll(items);
          _cursor = page['cursor'] as String?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _preview(Map<String, dynamic> request) {
    showModalBottomSheet<void>(
      context: context,
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${request['bloodGroup']} blood needed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${request['urgency']} • ${request['remainingUnits'] ?? request['quantity']} unit(s) • ${request['distanceKm'] is num ? (request['distanceKm'] as num).toStringAsFixed(1) : '?'} km',
                  ),
                  Text(
                    (request['hospitalName'] ?? '').toString().trim().isEmpty
                        ? 'Hospital not specified'
                        : request['hospitalName'].toString(),
                  ),
                  Text(
                    'Hospital address: ${(request['hospitalAddress'] ?? '').toString().trim().isEmpty ? 'Not provided' : request['hospitalAddress']}',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => RequestTrackingScreen(
                                requestId: request['id'] as String,
                              ),
                        ),
                      );
                    },
                    child: Text(AppLocalizations.of(context).viewRequest),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).bloodRequests)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).bloodRequests)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              TextButton(
                onPressed: _load,
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).bloodRequests),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(AppLocalizations.of(context).radius),
                Expanded(
                  child: Slider(
                    value: _radius,
                    min: 5,
                    max: 1000,
                    divisions: 995,
                    label: '${_radius.round()} km',
                    onChanged: (v) => setState(() => _radius = v),
                    onChangeEnd: (_) => _load(),
                  ),
                ),
                Text('${_requests.length}'),
              ],
            ),
          ),
          if (_cursor != null)
            TextButton(
              onPressed: () => _load(more: true),
              child: Text(AppLocalizations.of(context).loadMore),
            ),
          Expanded(
            child:
                _requests.isEmpty
                    ? Center(
                      child: Text(
                        AppLocalizations.of(context).noCompatibleRequests,
                      ),
                    )
                    : FlutterMap(
                      mapController: _map,
                      options: const MapOptions(
                        initialCenter: LatLng(30.3753, 69.3451),
                        initialZoom: 6,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.usmanch.bloodbank',
                        ),
                        MarkerLayer(
                          markers:
                              _requests
                                  .map(
                                    (request) => Marker(
                                      point: LatLng(
                                        (request['latitude'] as num).toDouble(),
                                        (request['longitude'] as num)
                                            .toDouble(),
                                      ),
                                      width: 56,
                                      height: 56,
                                      child: GestureDetector(
                                        onTap: () => _preview(request),
                                        child: const Icon(
                                          Icons.bloodtype,
                                          color: Colors.red,
                                          size: 42,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SimpleAttributionWidget(
                          source: Text('OpenStreetMap contributors'),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
