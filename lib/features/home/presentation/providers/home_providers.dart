// ============================================================
// lib/features/home/presentation/providers/home_providers.dart
// FINAL STABLE + LIVE FIRESTORE UPDATES + DISTANCE SORT
// FINAL CLEAN GEO VERSION
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../address/presentation/providers/address_providers.dart';
import '../../../home/data/repositories/vendor_repository_impl.dart';
import '../../../home/domain/entities/vendor_entity.dart';
import '../../../home/domain/repositories/i_vendor_repository.dart';

// ── Repository ───────────────────────────────────────────────
final vendorRepositoryProvider = Provider<IVendorRepository>(
  (_) => VendorRepositoryImpl(),
);

// ── Category ─────────────────────────────────────────────────
class CategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) {
    state = category;
  }
}

final vendorCategoryProvider =
    NotifierProvider<CategoryNotifier, String>(
  CategoryNotifier.new,
);

// ── Pure Veg ────────────────────────────────────────────────
class PureVegNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

final isPureVegProvider =
    NotifierProvider<PureVegNotifier, bool>(
  PureVegNotifier.new,
);

// ── LOCATION DISPLAY ─────────────────────────────────────────
final locationDisplayNameProvider =
    FutureProvider.autoDispose<String>((ref) async {
  final selectedAddress =
      ref.watch(selectedAddressProvider);

  final locationAsync =
      ref.watch(locationNotifierProvider);

  // ✅ Selected address priority
  if (selectedAddress != null &&
      selectedAddress.fullAddress.isNotEmpty) {
    return selectedAddress.fullAddress;
  }

  // ✅ Loading
  if (locationAsync.isLoading) {
    return 'Getting location...';
  }

  // ✅ Error
  if (locationAsync.hasError) {
    return 'Location unavailable';
  }

  final loc = locationAsync.value;

  if (loc == null) {
    return 'Location unavailable';
  }

  // ✅ Existing address
  if (loc.address != null &&
      loc.address!.trim().isNotEmpty) {
    return loc.address!;
  }

  // ✅ Reverse geocode fallback
  try {
    final placemarks =
        await placemarkFromCoordinates(
      loc.lat,
      loc.lng,
    );

    if (placemarks.isNotEmpty) {
      final p = placemarks.first;

      if ((p.subLocality ?? '').isNotEmpty) {
        return p.subLocality!;
      }

      if ((p.locality ?? '').isNotEmpty) {
        return p.locality!;
      }

      if ((p.administrativeArea ?? '').isNotEmpty) {
        return p.administrativeArea!;
      }
    }
  } catch (_) {}

  return 'Your location';
});

// ── 🔥 NEARBY VENDORS (LIVE REALTIME STREAM) ─────────────────
final nearbyVendorsProvider =
    StreamProvider.autoDispose<List<VendorEntity>>((ref) {
  final repo =
      ref.watch(vendorRepositoryProvider);

  final selectedAddress =
      ref.watch(selectedAddressProvider);

  // ✅ No selected address
  if (selectedAddress == null) {
    return Stream.value([]);
  }

  // ✅ Invalid coordinates
  if (selectedAddress.lat == 0 ||
      selectedAddress.lng == 0) {
    return Stream.value([]);
  }

  // ✅ Live Firestore stream
  final stream = repo.watchNearbyVendors(
    lat: selectedAddress.lat,
    lng: selectedAddress.lng,
    radiusKm: 5.0,
  );

  return stream.map((vendors) {
    final userLat = selectedAddress.lat;
    final userLng = selectedAddress.lng;

    // ── Distance Calculator ───────────────────────
    double distance(VendorEntity v) {
      final dx = v.lat - userLat;
      final dy = v.lng - userLng;

      return (dx * dx) + (dy * dy);
    }

    // ── Sort Logic ────────────────────────────────
    final sorted = [...vendors]
      ..sort((a, b) {
        // ✅ Open vendors first
        if (a.isCurrentlyOpen &&
            !b.isCurrentlyOpen) {
          return -1;
        }

        if (!a.isCurrentlyOpen &&
            b.isCurrentlyOpen) {
          return 1;
        }

        // ✅ Then nearest first
        return distance(a)
            .compareTo(distance(b));
      });

    return sorted;
  });
});

// ── 🔥 FILTERED VENDORS ──────────────────────────────────────
final filteredVendorsProvider =
    Provider.autoDispose<
        AsyncValue<List<VendorEntity>>>((ref) {
  final vendorsAsync =
      ref.watch(nearbyVendorsProvider);

  final isPureVeg =
      ref.watch(isPureVegProvider);

  final selectedCategory =
      ref.watch(vendorCategoryProvider);

  return vendorsAsync.when(
    loading: () =>
        const AsyncValue.loading(),

    error: (e, s) =>
        AsyncValue.error(e, s),

    data: (vendors) {
      var filtered = vendors;

      // ── Veg Filter ─────────────────────────────
      if (isPureVeg) {
        filtered = filtered
            .where(
              (v) => v.hasVegOptions,
            )
            .toList();
      }

      // ── Category Filter ───────────────────────
      if (selectedCategory != 'All') {
        filtered = filtered
            .where(
              (v) =>
                  v.category ==
                  selectedCategory,
            )
            .toList();
      }

      return AsyncValue.data(filtered);
    },
  );
});