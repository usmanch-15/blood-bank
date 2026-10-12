import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../../services/geo_location_service.dart';

class LocationSelection {
  final LatLng point;
  final String address;
  const LocationSelection({required this.point, required this.address});
}

class HospitalLocationScreen extends StatefulWidget {
  final LatLng? initial;
  const HospitalLocationScreen({super.key, this.initial});
  @override State<HospitalLocationScreen> createState() => _HospitalLocationScreenState();
}

class _HospitalLocationScreenState extends State<HospitalLocationScreen> {
  final _map = MapController();
  LatLng? _selected;
  String _address = '';
  String? _error;
  bool _locating = false, _resolvingAddress = false;

  @override void initState() { super.initState(); if (widget.initial != null) _select(widget.initial!); }

  Future<void> _select(LatLng point) async {
    setState(() { _selected = point; _address = 'Finding address…'; _error = null; _resolvingAddress = true; });
    try {
      final places = await placemarkFromCoordinates(point.latitude, point.longitude);
      final place = places.isEmpty ? null : places.first;
      final parts = [place?.name, place?.street, place?.locality, place?.administrativeArea, place?.country]
          .whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
      if (!mounted || _selected != point) return;
      setState(() { _address = parts.join(', '); _resolvingAddress = false; });
    } catch (_) {
      if (mounted && _selected == point) setState(() { _address = ''; _resolvingAddress = false; _error = 'Could not resolve an address. Check your connection and try again.'; });
    }
  }

  @override void dispose() { _map.dispose(); super.dispose(); }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final p = await GeoLocationService().getCurrentLocation();
      if (!mounted) return;
      final point = LatLng(p.latitude, p.longitude);
      _map.move(point, 16);
      await _select(point);
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _locating = false); }
  }

  void _confirm() {
    if (_selected == null || _resolvingAddress || _address.isEmpty) {
      setState(() => _error = 'Select a location and wait for its address to load.'); return;
    }
    Navigator.pop(context, LocationSelection(point: _selected!, address: _address));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Select Location')),
    body: Column(children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('Tap the map to place the pin. You can also drag the map beneath the centered pin to fine-tune the location.')),
      Expanded(child: FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: widget.initial ?? const LatLng(30.3753, 69.3451), initialZoom: widget.initial == null ? 5 : 14,
          onTap: (_, point) {
            _map.move(point, _selected == null ? 14 : 14);
            _select(point);
          },
          onPositionChanged: (position, _) { if (_selected != null && position.center != _selected) _select(position.center); },
        ),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.usmanch.bloodbank'),
          const IgnorePointer(child: Center(child: Padding(padding: EdgeInsets.only(bottom: 38), child: Icon(Icons.location_pin, color: Colors.red, size: 46)))),
          const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
        ],
      )),
      Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InputDecorator(decoration: const InputDecoration(labelText: 'Selected address', prefixIcon: Icon(Icons.location_on_outlined)), child: Text(_address.isEmpty ? 'Tap the map to select a location' : _address)),
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TextButton.icon(onPressed: _locating ? null : _locate, icon: const Icon(Icons.my_location), label: Text(_locating ? 'Locating…' : 'Use my location')),
          FilledButton(onPressed: _confirm, child: const Text('Confirm Location')),
        ]),
      ])),
    ]),
  );
}
