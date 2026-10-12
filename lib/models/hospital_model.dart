import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  static HospitalModel? fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final name = (data['name'] ?? data['hospitalName'] ?? '').toString().trim();
    final address =
        (data['address'] ?? data['area'] ?? data['location'] ?? '')
            .toString()
            .trim();
    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();
    if (name.isEmpty ||
        address.isEmpty ||
        lat == null ||
        lng == null ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return null;
    }
    return HospitalModel(
      id: doc.id,
      name: name,
      address: address,
      latitude: lat,
      longitude: lng,
    );
  }
}
