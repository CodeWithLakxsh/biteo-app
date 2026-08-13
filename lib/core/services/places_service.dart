import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  static Future<List<String>> getSuggestions(String input) async {
    final url =
        'YOUR_GOOGLE_PLACES_API_URL?input=$input&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] != 'OK') return [];

    return (data['predictions'] as List)
        .map((e) => e['description'] as String)
        .toList();
  }

  static Future<({double lat, double lng})?> getPlaceDetails(
      String place) async {
    final url =
        'YOUR_GOOGLE_GEOCODE_API_URL?address=$place&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] != 'OK') return null;

    final loc = data['results'][0]['geometry']['location'];

    return (
  lat: (loc['lat'] as num).toDouble(),
  lng: (loc['lng'] as num).toDouble(),
);
  }
}