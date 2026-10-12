import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/hospital_model.dart';

class LocationSelection {
  final LatLng point;
  final String address;
  final String hospitalName;
  final String hospitalId;
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

class _HospitalLocationScreenState extends State<HospitalLocationScreen> {
  final _map = MapController();
  List<HospitalModel> _hospitals = const [];
  HospitalModel? _selectedHospital;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('hospitals')
              .orderBy('name')
              .get();
      final hospitals =
          snapshot.docs
              .map(HospitalModel.fromDocument)
              .whereType<HospitalModel>()
              .toList();
      if (!mounted) return;
      setState(() {
        _hospitals = hospitals;
        _loading = false;
        if (hospitals.isEmpty) {
          _error =
              'No hospitals with a complete address and valid coordinates are configured.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load the hospital list. Check your connection.';
        });
      }
    }
  }

  void _selectHospital(HospitalModel hospital) {
    setState(() {
      _selectedHospital = hospital;
      _error = null;
    });
    _map.move(LatLng(hospital.latitude, hospital.longitude), 15);
  }

  void _confirm() {
    final hospital = _selectedHospital;
    if (hospital == null) {
      setState(() => _error = 'Select a hospital from the list.');
      return;
    }
    Navigator.pop(
      context,
      LocationSelection(
        point: LatLng(hospital.latitude, hospital.longitude),
        address: hospital.address,
        hospitalName: hospital.name,
        hospitalId: hospital.id,
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
    final hospital = _selectedHospital;
    final center =
        hospital == null
            ? const LatLng(30.3753, 69.3451)
            : LatLng(hospital.latitude, hospital.longitude);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Hospital')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<HospitalModel>(
              initialValue: hospital,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Hospital name',
                prefixIcon: Icon(Icons.local_hospital_outlined),
                border: OutlineInputBorder(),
              ),
              items:
                  _hospitals
                      .map(
                        (h) => DropdownMenuItem(
                          value: h,
                          child: Text(h.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
              onChanged:
                  _loading
                      ? null
                      : (value) {
                        if (value != null) _selectHospital(value);
                      },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'The map shows the selected hospital and its surrounding area.',
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: center,
                initialZoom: hospital == null ? 5 : 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.usmanch.bloodbank',
                ),
                if (hospital != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(hospital.latitude, hospital.longitude),
                        width: 52,
                        height: 52,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 46,
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Hospital area / address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  child: Text(
                    hospital?.address ??
                        'Select a hospital to show its address',
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _loading || hospital == null ? null : _confirm,
                  child: const Text('Confirm Hospital'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
