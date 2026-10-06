import 'package:geolocator/geolocator.dart';
import '../models/donor_model.dart';
import '../utils/location_helper.dart';
import 'workflow_service.dart';
class GeoLocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is blocked. Open app settings to enable it.',
      );
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }


  static const Map<String, List<String>> compatibleDonorGroups = {
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'A-': ['A-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    'AB-': ['A-', 'B-', 'AB-', 'O-'],
    'O+': ['O+', 'O-'],
    'O-': ['O-'],
  };


Future<List<DonorWithDistance>> findCompatibleDonorsWithDistance({required double receiverLat,required double receiverLng,String? bloodGroup,double maxRadiusKm=50}) async {
 final result=await WorkflowService.call('findDonors',{'latitude':receiverLat,'longitude':receiverLng,'bloodGroup':bloodGroup,'radiusKm':maxRadiusKm});
 return (result['donors'] as List).map((raw){final d=Map<String,dynamic>.from(raw);return DonorWithDistance(donor:DonorModel.fromFirestore(d,d['uid']),distanceKm:(d['distanceKm'] as num).toDouble());}).toList();
}
Future<List<DonorModel>> findNearbyDonors({required double receiverLat,required double receiverLng,String? bloodGroup,double radiusKm=15}) async => (await findCompatibleDonorsWithDistance(receiverLat:receiverLat,receiverLng:receiverLng,bloodGroup:bloodGroup,maxRadiusKm:radiusKm)).map((d)=>d.donor).toList();
Future<List<DonorModel>> findNearbyDonorsWithExpand({required double receiverLat,required double receiverLng,String? bloodGroup,List<double> radiiKm=const [10,30,50]}) async {
 final all=await findCompatibleDonorsWithDistance(receiverLat:receiverLat,receiverLng:receiverLng,bloodGroup:bloodGroup,maxRadiusKm:radiiKm.last);
 for(final radius in radiiKm){final donors=all.where((d)=>d.distanceKm<=radius).map((d)=>d.donor).toList();if(donors.isNotEmpty)return donors;}return [];
}
double distanceBetween(double lat1,double lng1,double lat2,double lng2)=>LocationHelper.calculateDistance(lat1,lng1,lat2,lng2);
}
class DonorWithDistance {final DonorModel donor;final double distanceKm;DonorWithDistance({required this.donor,required this.distanceKm});}
