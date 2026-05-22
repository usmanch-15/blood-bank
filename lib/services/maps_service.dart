import 'dart:convert';
import 'package:http/http.dart' as http;

class MapsService {
  static const String _apiKey = String.fromEnvironment('MAPS_API_KEY');

  Future<Map<String, dynamic>> getDistanceAndEta({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
          '?origins=$originLat,$originLng'
          '&destinations=$destLat,$destLng'
          '&key=$_apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final element = data['rows'][0]['elements'][0];
      return {
        'distance': element['distance']['text'],
        'duration': element['duration']['text'],
        'distanceValue': element['distance']['value'],
        'durationValue': element['duration']['value'],
      };
    }
    throw Exception('Maps API error: ${response.statusCode}');
  }
}