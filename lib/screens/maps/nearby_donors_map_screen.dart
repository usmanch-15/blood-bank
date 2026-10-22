import '../../utils/feedback.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/geo_location_service.dart';
import '../../services/workflow_service.dart';
import '../../widgets/report_misuse_button.dart';
import '../requests/request_tracking_screen.dart';
import '../communication/voice_call_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/app_constants.dart';
import '../../widgets/premium_ui.dart';
import '../../widgets/premium_states.dart';

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
  double _radius = 5;
  final _map = MapController();
  static const _radii = [5.0, 10.0, 25.0, 50.0, 100.0, 250.0, 500.0, 1000.0];

  void _fitRange() {
    if (_center == null || _list || _loading) return;
    const distance = Distance();
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([
          distance.offset(_center!, _radius * 1000, 0),
          distance.offset(_center!, _radius * 1000, 90),
          distance.offset(_center!, _radius * 1000, 180),
          distance.offset(_center!, _radius * 1000, 270),
        ]),
        padding: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  bool _loading = true, _sending = false, _list = false;
  final Set<String> _notReady = <String>{};
  String? _cursor;
  bool _loadingMore = false;
  int _loadVersion = 0;
  @override
  void initState() {
    super.initState();
    _group = widget.bloodGroup;
    _list = widget.listInitially;
    _loadNotReady();
    _load();
  }

  Future<void> _loadNotReady() async {
    final id = widget.requestId;
    if (id == null) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('blood_requests').doc(id).collection('notReadyDonors').get();
      if (mounted) setState(() => _notReady.addAll(snap.docs.map((d) => d.id)));
    } catch (_) {}
  }

  Future<void> _load({bool append = false}) async {
    if (append) setState(() => _loadingMore = true);
    final version = ++_loadVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      LatLng center;
      if (widget.requestId != null) {
        final r = await WorkflowService.request(widget.requestId!);
        if (r['latitude'] == null) {
          throw StateError(
            'The meeting point is private. Open request tracking after acceptance.',
          );
        }
        center = LatLng(
          (r['latitude'] as num).toDouble(),
          (r['longitude'] as num).toDouble(),
        );
      } else {
        final p = await GeoLocationService().getCurrentLocation();
        center = LatLng(p.latitude, p.longitude);
      }
      final page = await GeoLocationService().findCompatibleDonorsPage(
        receiverLat: center.latitude,
        receiverLng: center.longitude,
        bloodGroup: _group,
        maxRadiusKm: _radius,
        cursor: append ? _cursor : null,
      );
      if (mounted && version == _loadVersion) {
        setState(() {
          _donors = append ? [..._donors, ...page.donors] : page.donors;
          _cursor = page.cursor;
          _center = center;
        });
      }
    } catch (e) {
      if (mounted && version == _loadVersion) {
        setState(() => _error = AppFeedback.message(e));
        if (e.toString().toLowerCase().contains('permission')) {
          showPermissionDeniedSheet(context, 'Location');
        }
      }
    } finally {
      if (mounted && version == _loadVersion) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
        if (!_list) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fitRange();
          });
        }
      }
    }
  }

  Future<void> _notify(List<DonorWithDistance> targets) async {
    if (widget.requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).createRequestBeforeNotify),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await WorkflowService.call('notifyRequest', {
        'requestId': widget.requestId,
        'radiusKm': _radius,
        'userIds': targets.map((d) => d.donor.uid).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).donorsQueued(
                result['count'] as int,
                (result['remaining'] as num?)?.toInt() ?? 0,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppFeedback.message(e))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _card(DonorWithDistance d) => PremiumCard(
    child: ListTile(
      leading: CircleAvatar(
        backgroundImage:
            (d.donor.profileImageUrl?.isNotEmpty ?? false)
                ? NetworkImage(d.donor.profileImageUrl!)
                : null,
        child:
            (d.donor.profileImageUrl?.isNotEmpty ?? false)
                ? null
                : Text(d.donor.bloodGroup ?? ''),
      ),
      title: Text(d.donor.name),
      subtitle: Text(
        AppLocalizations.of(
          context,
        ).donorApproximateDistance(d.distanceKm.toStringAsFixed(1)),
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.requestId != null)
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'notify') _notify([d]);
                if (action == 'call') {
                  _callAndAskReady(d);
                }
              },
              itemBuilder:
                  (_) => [
                    PopupMenuItem(
                      value: 'call',
                      child: Text(AppLocalizations.of(context).callInApp),
                    ),
                    PopupMenuItem(
                      value: 'notify',
                      child: Text(AppLocalizations.of(context).sendRequest),
                    ),
                  ],
            ),
          ReportMisuseButton(
            targetUserId: d.donor.uid,
            targetRequestId: widget.requestId,
          ),
        ],
      ),
    ),
  );
  Future<void> _callAndAskReady(DonorWithDistance donor) async {
    final connected = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => VoiceCallScreen(requestId: widget.requestId!, calleeId: donor.donor.uid)));
    if (!mounted || connected != true) return;
    final l = AppLocalizations.of(context);
    final ready = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text(l.donorReadyQuestion(donor.donor.name)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.donorReadyNo)), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.donorReadyYes))]));
    if (ready == false && mounted) {
      await WorkflowService.call('markDonorNotReady', {'requestId': widget.requestId, 'donorId': donor.donor.uid});
      if (mounted) setState(() => _notReady.add(donor.donor.uid));
      return;
    }
    if (ready == true && mounted) {
      try {
        await WorkflowService.call('inviteDonor', {'requestId': widget.requestId, 'donorId': donor.donor.uid});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).invitationSent)));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).invitationFailed(AppFeedback.message(e)))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _donors
            .where(
              (d) =>
                  !_notReady.contains(d.donor.uid) &&
                  d.distanceKm <= _radius &&
                  d.donor.name.toLowerCase().contains(_search.toLowerCase()),
            )
            .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).findNearbyDonors),
        actions: [
          IconButton(
            onPressed: () => setState(() => _list = !_list),
            tooltip:
                _list
                    ? AppLocalizations.of(context).mapViewLabel
                    : AppLocalizations.of(context).listViewLabel,
            icon: Icon(_list ? Icons.map : Icons.list),
          ),
          IconButton(
            onPressed: _load,
            tooltip: AppLocalizations.of(context).refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body:
          _loading
              ? const PremiumLoading(rows: 3)
              : _error != null
              ? PremiumErrorState(onRetry: _load, message: _error)
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context).searchDonorName,
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                        if (widget.bloodGroup == null)
                          DropdownButton<String>(
                            value: _group,
                            hint: Text(
                              AppLocalizations.of(context).anyBloodGroup,
                            ),
                            isExpanded: true,
                            items:
                                AppConstants.bloodGroups
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).compatibleWith(g),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (g) {
                              setState(() => _group = g);
                              _load();
                            },
                          ),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).donorCountWithin(visible.length, _radius.round()),
                        ),
                        Text(
                          AppLocalizations.of(context).matchingMedicalNote,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Slider(
                          value: _radius,
                          min: 5,
                          max: 1000,
                          divisions: 995,
                          label: '${_radius.round()} km',
                          onChanged: (v) => setState(() => _radius = v),
                          onChangeEnd: (_) => _load(),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final radius in _radii)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text('${radius.round()} km'),
                                    selected: _radius == radius,
                                    onSelected: (_) {
                                      setState(() => _radius = radius);
                                      _load();
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        _list
                            ? ListView(
                              children: [
                                if (visible.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).noCompatibleDonors,
                                    ),
                                  ),
                                if (visible.isNotEmpty) ...visible.map(_card),
                                if (_cursor != null)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: OutlinedButton(
                                      onPressed:
                                          _loadingMore
                                              ? null
                                              : () => _load(append: true),
                                      child: Text(
                                        _loadingMore
                                            ? 'Loading…'
                                            : 'Load more donors',
                                      ),
                                    ),
                                  ),
                              ],
                            )
                            : FlutterMap(
                              mapController: _map,
                              options: MapOptions(
                                initialCenter: _center!,
                                initialZoom: 11,
                                onMapReady: _fitRange,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.usmanch.bloodbank',
                                ),
                                CircleLayer(
                                  circles: [
                                    CircleMarker(
                                      point: _center!,
                                      radius: _radius * 1000,
                                      useRadiusInMeter: true,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.08),
                                      borderColor:
                                          Theme.of(context).colorScheme.primary,
                                      borderStrokeWidth: 2,
                                    ),
                                  ],
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
                          if (_cursor != null)
                            OutlinedButton(
                              onPressed:
                                  _loadingMore
                                      ? null
                                      : () => _load(append: true),
                              child: Text(
                                _loadingMore ? 'Loading…' : 'Load more donors',
                              ),
                            ),
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
                              child: Text(
                                AppLocalizations.of(context).trackRequest,
                              ),
                            ),
                          FilledButton(
                            onPressed:
                                _sending || visible.isEmpty
                                    ? null
                                    : () => _notify(visible),
                            child: Text(
                              _sending
                                  ? AppLocalizations.of(context).queuing
                                  : AppLocalizations.of(
                                    context,
                                  ).notifyMatchingDonors,
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
