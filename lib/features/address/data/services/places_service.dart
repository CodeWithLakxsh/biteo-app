import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/providers/location_provider.dart';

class PlacesService {
  /// Google Places/Geocoding REST API key.
  ///
  /// Placeholder — replace with your own key for local development.
  /// Real keys must NEVER be committed. On Android the Google Maps SDK key
  /// is injected at build time via the manifest placeholder
  /// (android/app/build.gradle.kts reads android/local.properties, which is
  /// git-ignored). Restrict this key in Google Cloud Console by application
  /// and package/bundle identifier.
  static const String apiKey = "YOUR_GOOGLE_MAPS_API_KEY";

  // 🔍 Autocomplete
  static Future<List<String>> getSuggestions(String input) async {
    if (input.isEmpty) return [];

    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=${Uri.encodeComponent(input)}"
        "&key=$apiKey"
        "&components=country:in",
      );

      final res = await http.get(url);
      final data = json.decode(res.body);

      if (data['status'] != 'OK') {
  print("Places API Error: ${data['status']}");
  return [];
}

      return (data['predictions'] as List)
          .map((e) => e['description'] as String)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // 📍 Convert place → lat/lng
  static Future<UserLocation?> getPlaceDetails(String description) async {
    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json"
        "?address=${Uri.encodeComponent(description)}"
        "&key=$apiKey",
      );

      final res = await http.get(url);
      final data = json.decode(res.body);

      if (data['status'] != 'OK') return null;

      final result = data['results'][0];
      final location = result['geometry']['location'];

      String? city;
String? state;

final components = result['address_components'] as List;

for (var c in components) {
  final types = c['types'] as List;

  if (types.contains('locality')) {
    city = c['long_name'];
  }

  if (types.contains('administrative_area_level_1')) {
    state = c['long_name'];
  }
}

return UserLocation(
  lat: (location['lat'] as num).toDouble(),
  lng: (location['lng'] as num).toDouble(),
  address: result['formatted_address'],
  city: city,
  state: state,
);
    } catch (_) {
      return null;
    }
  }
}