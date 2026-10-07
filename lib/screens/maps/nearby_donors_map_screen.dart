import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/geo_location_service.dart';
import '../../services/workflow_service.dart';
import '../../widgets/report_misuse_button.dart';
import '../requests/request_tracking_screen.dart';

/// List and map render the same server-filtered, consented donor results.
class NearbyDonorsMapScreen extends StatefulWidget {
  final String? bloodGroup, requestId;
  final int? unitsNeeded;
  final bool listInitially;
  const NearbyDonorsMapScreen({
    super.key,
    this.bloodGroup,
    this.requestId,
    this.unitsNeeded,
    this.listInitially = false,
  });
  @override
  State<NearbyDonorsMapScreen> createState() => _NearbyDonorsMapScreenState();
}

class _NearbyDonorsMapScreenState extends State<NearbyDonorsMapScreen> {
  List<DonorWithDistance> _donors = [];
  LatLng? _center;
  String? _error, _group;
  String _search = '';
  double _radius = 15;
  bool _loading = true, _sending = false, _list = false;
  @override
  void initState() {
    super.initState();
    _group = widget.bloodGroup;
    _list = widget.listInitially;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      LatLng center;
      if (widget.requestId != null) {
        final r = await WorkflowService.request(widget.requestId!);
        if (r['latitude'] == null)
          throw StateError(
            'The meeting point is private. Open request tracking after acceptance.',
          );
        center = LatLng(
          (r['latitude'] as num).toDouble(),
          (r['longitude'] as num).toDouble(),
        );
      } else {
        final p = await GeoLocationService().getCurrentLocation();
        center = LatLng(p.latitude, p.longitude);
      }
      final donors = await GeoLocationService()
          .findCompatibleDonorsWithDistance(
            receiverLat: center.latitude,
            receiverLng: center.longitude,
            bloodGroup: _group,
          );
      if (mounted)
        setState(() {
          _donors = donors;
          _center = center;
        });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _notify(List<DonorWithDistance> targets) async {
    if (widget.requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a blood request first to notify donors.'),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await WorkflowService.call('notifyRequest', {
        'requestId': widget.requestId,
        'userIds': targets.map((d) => d.donor.uid).toList(),
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result['count']} matching donor inboxes queued. Delivery is not guaranteed.',
            ),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _card(DonorWithDistance d) => Card(
    child: ListTile(
      leading: CircleAvatar(child: Text(d.donor.bloodGroup ?? '')),
      title: Text(d.donor.name),
      subtitle: Text(
        '${d.distanceKm.toStringAsFixed(1)} km approximately • Available\nContact is shared after acceptance.',
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.requestId != null)
            IconButton(
              onPressed: _sending ? null : () => _notify([d]),
              tooltip: 'Notify donor',
              icon: const Icon(Icons.notifications_active_outlined),
            ),
          ReportMisuseButton(
            targetUserId: d.donor.uid,
            targetRequestId: widget.requestId,
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final visible =
        _donors
            .where(
              (d) =>
                  d.distanceKm <= _radius &&
                  d.donor.name.toLowerCase().contains(_search.toLowerCase()),
            )
            .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Nearby Donors'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _list = !_list),
            tooltip: _list ? 'Map view' : 'List view',
            icon: Icon(_list ? Icons.map : Icons.list),
          ),
          IconButton(
            onPressed: _load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search donor name',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                        if (widget.bloodGroup == null)
                          DropdownButton<String>(
                            value: _group,
                            hint: const Text('Any blood group'),
                            isExpanded: true,
                            items:
                                GeoLocationService.compatibleDonorGroups.keys
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g,
                                        child: Text('Compatible with $g'),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (g) {
                              setState(() => _group = g);
                              _load();
                            },
                          ),
                        Text(
                          '${visible.length} donors within ${_radius.round()} km',
                        ),
                        Slider(
                          value: _radius,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${_radius.round()} km',
                          onChanged: (v) => setState(() => _radius = v),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        _list
                            ? ListView(
                              children:
                                  visible.isEmpty
                                      ? [
                                        const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Text(
                                            'No available compatible donors in this radius. Try expanding it.',
                                          ),
                                        ),
                                      ]
                                      : visible.map(_card).toList(),
                            )
                            : FlutterMap(
                              options: MapOptions(
                                initialCenter: _center!,
                                initialZoom: 11,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.usmanch.bloodbank',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _center!,
                                      child: const Icon(
                                        Icons.local_hospital,
                                        color: Colors.red,
                                      ),
                                    ),
                                    ...visible.map(
                                      (d) => Marker(
                                        point: LatLng(
                                          d.donor.latitude!,
                                          d.donor.longitude!,
                                        ),
                                        child: IconButton(
                                          tooltip: d.donor.name,
                                          icon: const Icon(
                                            Icons.person_pin_circle,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => showModalBottomSheet(
                                                context: context,
                                                builder:
                                                    (_) => SafeArea(
                                                      child: _card(d),
                                                    ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SimpleAttributionWidget(
                                  source: Text('OpenStreetMap contributors'),
                                ),
                              ],
                            ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 12,
                        children: [
                          if (widget.requestId != null)
                            OutlinedButton(
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => RequestTrackingScreen(
                                            requestId: widget.requestId!,
                                          ),
                                    ),
                                  ),
                              child: const Text('Track request'),
                            ),
                          FilledButton(
                            onPressed:
                                _sending || visible.isEmpty
                                    ? null
                                    : () => _notify(visible),
                            child: Text(
                              _sending ? 'Queuing…' : 'Notify matching donors',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
