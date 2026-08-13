// =============================================================
// lib/core/services/data_migration_service.dart
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class DataMigrationService {
  static Future<void> fixVendorGeoIfNeeded() async {
    try {
      final collection = FirebaseFirestore.instance.collection('vendors');
      final vendors = await collection.get();

      for (var doc in vendors.docs) {
        final data = doc.data();

        double? lat;
        double? lng;

        // ✅ CASE 1: ROOT LEVEL (YOUR CURRENT STRUCTURE)
        if (data['lat'] != null && data['lng'] != null) {
          lat = (data['lat'] as num).toDouble();
          lng = (data['lng'] as num).toDouble();
        }

        // ✅ CASE 2: LOCATION MAP (OLD STRUCTURE)
        else if (data['location'] != null) {
          final location = data['location'] as Map<String, dynamic>;
          lat = (location['lat'] as num?)?.toDouble();
          lng = (location['lng'] as num?)?.toDouble();
        }

        // ❌ If still null → skip
        if (lat == null || lng == null) {
          print("❌ Missing lat/lng for vendor: ${doc.id}");
          continue;
        }

        // ✅ CREATE GEO (ALWAYS)
        final geo = GeoFirePoint(
          GeoPoint(lat, lng),
        );

        await doc.reference.update({
          'geo': geo.data,
        });

        print("✅ FIXED GEO: ${doc.id}");
      }

      print("🎯 Vendor geo migration completed");
    } catch (e) {
      print("❌ Migration error: $e");
    }
  }
}