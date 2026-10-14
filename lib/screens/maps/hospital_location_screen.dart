import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../models/hospital_model.dart';
import '../../utils/location_helper.dart';

class LocationSelection {
  final LatLng point;
  final String address, hospitalName, hospitalId;
  const LocationSelection({
    required this.point,
    required this.address,
    required this.hospitalName,
    required this.hospitalId,
  });
}

class HospitalLocationScreen extends StatefulWidget {
  final LatLng? initial;
  const HospitalLocationScreen({super.key, this.initial});
  @override
  State<HospitalLocationScreen> createState() => _HospitalLocationScreenState();
}

class _Place {
  final String name;
  final LatLng point;
  final String id;
  const _Place(this.name, this.point, [this.id = '']);
}

class _HospitalLocationScreenState extends State<HospitalLocationScreen> {
  final _map = MapController(),
      _search = TextEditingController(),
      _mapKey = GlobalKey();
  LatLng? _point;
  String _address = '', _name = '', _hospitalId = '';
  List<_Place> _results = const [];
  String? _error;
  bool _locating = false, _searching = false;
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _point = widget.initial;
    _loadHospitals();
    if (_point != null) _reverse(_point!);
  }

  Future<void> _loadHospitals() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('hospitals')
              .orderBy('name')
              .get();
      _configuredHospitals =
          snapshot.docs
              .map(HospitalModel.fromDocument)
              .whereType<HospitalModel>()
              .toList();
    } catch (_) {
      // The OSM search and map remain usable when the optional catalog is offline.
    }
  }

  List<HospitalModel> _configuredHospitals = const [];

  void _setPoint(LatLng p, {String? address, String? name, String id = ''}) {
    setState(() {
      _point = p;
      _address = address ?? _address;
      _name = name ?? '';
      _hospitalId = id;
      _error = null;
    });
    if (address == null) _reverse(p);
  }

  Future<void> _reverse(LatLng p) async {
    final a = await LocationHelper.getAddressFromCoordinates(
      p.latitude,
      p.longitude,
    );
    if (mounted && _point == p)
      setState(() => _address = a ?? 'Selected map location');
  }

  Future<void> _current() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw StateError(
          'Location services are disabled. Enable them or search for a place.',
        );
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw StateError('Location permission was denied.');
      if (permission == LocationPermission.deniedForever)
        throw StateError(
          'Location permission is permanently denied. Open app settings or search for a place.',
        );
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = LatLng(p.latitude, p.longitude);
      _setPoint(point);
      _map.move(point, 15);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
    }
    if (mounted) setState(() => _locating = false);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _results = const []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _searchPlaces(value.trim()),
    );
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _searching = true);
    try {
      final catalogMatches = _configuredHospitals
          .where(
            (hospital) =>
                hospital.name.toLowerCase().contains(query.toLowerCase()) ||
                hospital.address.toLowerCase().contains(query.toLowerCase()),
          )
          .map(
            (hospital) => _Place(
              hospital.name,
              LatLng(hospital.latitude, hospital.longitude),
              hospital.id,
            ),
          );
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '8',
        'countrycodes': 'pk',
      });
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'BloodConnect/1.0 (OpenStreetMap geocoding contact via app)',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200)
        throw StateError('Search service unavailable.');
      final data = jsonDecode(response.body) as List;
      final found = [
        ...catalogMatches,
        ...data.map((e) {
          final m = Map<String, dynamic>.from(e);
          return _Place(
            m['display_name'] as String,
            LatLng(
              double.parse(m['lat'] as String),
              double.parse(m['lon'] as String),
            ),
          );
        }),
      ];
      if (mounted)
        setState(() {
          _results = found;
          _error =
              found.isEmpty
                  ? 'No places found. Try a hospital name or broader address.'
                  : null;
        });
    } catch (_) {
      if (mounted)
        setState(
          () =>
              _error =
                  'Could not search right now. Check your connection and retry.',
        );
    }
    if (mounted) setState(() => _searching = false);
  }

  Widget _marker() => GestureDetector(
    onPanUpdate: (d) {
      final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null)
        _setPoint(_map.camera.offsetToCrs(box.globalToLocal(d.globalPosition)));
    },
    child: const Icon(Icons.location_pin, color: Colors.red, size: 52),
  );
  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _point ?? const LatLng(30.3753, 69.3451);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose location'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search hospital or address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searching
                        ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (_results.isNotEmpty)
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder:
                    (_, i) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(
                        _results[i].name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        final r = _results[i];
                        HospitalModel? catalog;
                        for (final hospital in _configuredHospitals) {
                          if (hospital.id == r.id) {
                            catalog = hospital;
                            break;
                          }
                        }
                        _setPoint(
                          r.point,
                          address: catalog?.address ?? r.name,
                          name: catalog?.name,
                          id: r.id,
                        );
                        _map.move(r.point, 15);
                        setState(() => _results = const []);
                      },
                    ),
              ),
            ),
          Expanded(
            child: RepaintBoundary(
              key: _mapKey,
              child: FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _point == null ? 5 : 15,
                  onTap: (_, p) => _setPoint(p),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.usmanch.bloodbank',
                  ),
                  if (_point != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _point!,
                          width: 60,
                          height: 60,
                          child: _marker(),
                        ),
                      ],
                    ),
                  const SimpleAttributionWidget(
                    source: Text('OpenStreetMap contributors'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _address.isEmpty
                            ? 'Tap the map, drag the pin, or search for a place.'
                            : _address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: _locating ? null : _current,
                      tooltip: 'Use current location',
                      icon:
                          _locating
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.my_location),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            _point == null
                                ? null
                                : () => Navigator.pop(
                                  context,
                                  LocationSelection(
                                    point: _point!,
                                    address:
                                        _address.isEmpty
                                            ? 'Selected map location'
                                            : _address,
                                    hospitalName:
                                        _name.isEmpty
                                            ? 'Selected location'
                                            : _name,
                                    hospitalId: _hospitalId,
                                  ),
                                ),
                        child: const Text('Confirm Location'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
