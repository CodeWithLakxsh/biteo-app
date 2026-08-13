// ============================================================
// lib/features/home/domain/repositories/i_vendor_repository.dart
// Contract for vendor data. Domain never imports Firebase.
// ============================================================
import '../entities/vendor_entity.dart';

abstract class IVendorRepository {
  /// Returns a real-time stream of vendors within [radiusKm] of the
  /// given coordinates. Emits a new list whenever Firestore data changes
  /// (vendor goes offline, new vendor joins, etc.)
  Stream<List<VendorEntity>> watchNearbyVendors({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  });

  /// One-time fetch of a single vendor by ID.
  /// Used by the Vendor Detail screen in Milestone 5.
  Future<VendorEntity?> getVendorById(String vendorId);
}