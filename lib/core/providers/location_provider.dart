// ============================================================
// lib/core/providers/location_provider.dart
// FINAL ABSOLUTE VERSION (ALL BUGS FIXED)
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/address/domain/entities/address_entity.dart';
import '../../features/address/presentation/providers/address_providers.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

// ── Location Failure ──────────────────────────────────────────
enum LocationFailure {
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  unknown,
}

extension LocationFailureMessage on LocationFailure {
  String get userMessage => switch (this) {
        LocationFailure.permissionDenied =>
          'Location access denied. Please allow location.',
        LocationFailure.permissionPermanentlyDenied =>
          'Enable location permission in Settings.',
        LocationFailure.serviceDisabled =>
          'Turn on GPS to continue.',
        LocationFailure.unknown =>
          'Could not get location. Try again.',
      };
}

// ── UserLocation MODEL ────────────────────────────
class UserLocation {
  final double lat;
  final double lng;
  final double? accuracyMeters;

  final String? city;
  final String? state;
  final String? address;

  const UserLocation({
    required this.lat,
    required this.lng,
    this.accuracyMeters,
    this.city,
    this.state,
    this.address,
  });
}

// ── Location Notifier ────────────────────────────
class LocationNotifier extends AsyncNotifier<UserLocation> {
  UserLocation? _cachedLocation;
  @override
Future<UserLocation> build() async {
  final prefs = await SharedPreferences.getInstance();

  try {
    // ✅ CACHE FIX
    if (_cachedLocation != null) {
      return _cachedLocation!;
    }

    final fresh = await _fetchLocation();
    _cachedLocation = fresh;

    await prefs.setDouble('lat', fresh.lat);
    await prefs.setDouble('lng', fresh.lng);

    if (fresh.city != null) {
      await prefs.setString('city', fresh.city!);
    }
    if (fresh.state != null) {
      await prefs.setString('state', fresh.state!);
    }
    if (fresh.address != null) {
      await prefs.setString('address', fresh.address!);
    }

    return fresh;
  } catch (e) {
    final lat = prefs.getDouble('lat');
    final lng = prefs.getDouble('lng');

    if (lat != null && lng != null && lat != 0 && lng != 0) {
      _log.w('[Location] Using FALLBACK saved location');

      return UserLocation(
        lat: lat,
        lng: lng,
        city: prefs.getString('city'),
        state: prefs.getString('state'),
        address: prefs.getString('address'),
      );
    }

    rethrow;
  }
}

  // ── FETCH GPS ─────────────────────────
  Future<UserLocation> _fetchLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw LocationFailure.serviceDisabled;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationFailure.permissionDenied;
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure.permissionPermanentlyDenied;
    }

    try {
final position = await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.low,
    timeLimit: Duration(seconds: 5),
  ),
).timeout(
  const Duration(seconds: 5),
  onTimeout: () async {
    throw LocationFailure.unknown;
  },
);

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.isNotEmpty ? placemarks.first : null;

      final address = [
        place?.street,
        place?.subLocality,
        place?.locality,
        place?.administrativeArea,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      _log.i('[Location] GPS → ${place?.locality}, ${place?.administrativeArea}');

      return UserLocation(
        lat: position.latitude,
        lng: position.longitude,
        accuracyMeters: position.accuracy,
        city: place?.locality,
        state: place?.administrativeArea,
        address: address,
      );
    } catch (e) {
      _log.e('[Location] Error', error: e);
      throw LocationFailure.unknown;
    }
  }

  // ── SAVE LOCATION ─────────────────────
  Future<void> saveLocation(UserLocation location) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('lat', location.lat);
    await prefs.setDouble('lng', location.lng);

    if (location.city?.isNotEmpty ?? false) {
      await prefs.setString('city', location.city!);
    } else {
      await prefs.remove('city');
    }

    if (location.state?.isNotEmpty ?? false) {
      await prefs.setString('state', location.state!);
    } else {
      await prefs.remove('state');
    }

    if (location.address?.isNotEmpty ?? false) {
      await prefs.setString('address', location.address!);
    } else {
      await prefs.remove('address');
    }

    _log.i('[Location] Saved → ${location.city}, ${location.state}');
    state = AsyncValue.data(location);
  }

  // ── 🔥 SAVE LAST SELECTED ADDRESS (CRITICAL FIX)
  Future<void> saveLastUsedAddressId(String addressId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'last_address_id': addressId,
      }, SetOptions(merge: true));

      _log.i('[Location] Saved last_address_id → $addressId');
    } catch (e) {
      _log.e('[Location] Failed to save last_address_id', error: e);
    }
  }

  // ── REFRESH ──────────────────────────
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  // ── AUTO SELECT NEARBY ADDRESS ───────
  Future<AddressEntity?> _getNearbyAddress() async {
    try {
      final current = state is AsyncData ? state.value : null;
      if (current == null) return null;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final lat = (data['lat'] ?? 0).toDouble();
        final lng = (data['lng'] ?? 0).toDouble();

        final distance = Geolocator.distanceBetween(
          current.lat,
          current.lng,
          lat,
          lng,
        );

        if (distance <= 500) {
          return AddressEntity(
            id: doc.id,
            label: data['label'] ?? 'other',
            fullAddress: data['fullAddress'] ?? '',
            lat: lat,
            lng: lng,
            geohash: data['geohash'] ?? '',
            isDefault: data['isDefault'] ?? false,
            createdAt: null,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── LAST USED ADDRESS ───────────
  Future<AddressEntity?> _getLastUsedAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final lastId = userDoc.data()?['last_address_id'];
      if (lastId == null) return null;

      final addrDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(lastId)
          .get();

      if (!addrDoc.exists) return null;

      final data = addrDoc.data()!;

      return AddressEntity(
        id: addrDoc.id,
        label: data['label'] ?? 'other',
        fullAddress: data['fullAddress'] ?? '',
        lat: (data['lat'] ?? 0).toDouble(),
        lng: (data['lng'] ?? 0).toDouble(),
        geohash: data['geohash'] ?? '',
        isDefault: data['isDefault'] ?? false,
        createdAt: null,
      );
    } catch (e) {
      return null;
    }
  }

  // ── INITIALISE ───────────────────────
  Future<void> initialise(WidgetRef ref) async {
    try {
      state = const AsyncValue.loading();

      // ✅ FIX: prevent empty UI on first frame
      ref.read(selectedAddressProvider.notifier).state = AddressEntity(
        id: 'temp',
        label: 'Current Location',
        fullAddress: 'Getting location...',
        lat: 0,
        lng: 0,
        geohash: '',
        isDefault: false,
        createdAt: null,
      );

UserLocation location;

try {
  location = await build().timeout(
    const Duration(seconds: 3),
  );
} catch (_) {
  location = const UserLocation(
    lat: 0,
    lng: 0,
    city: 'Unknown',
    state: 'Unknown',
    address: 'Location unavailable',
  );
}
      state = AsyncValue.data(location);

      AddressEntity? selected;

      // ✅ FIXED PRIORITY
      // ✅ STEP 1: NEARBY ADDRESS (HIGHEST PRIORITY)
      selected = await _getNearbyAddress();

      // ✅ STEP 2: LAST USED (ONLY IF NO NEARBY)
      selected ??= await _getLastUsedAddress();

      // ✅ STEP 3: FALLBACK → CURRENT LOCATION
      selected ??= AddressEntity(
        id: 'temp',
        label: 'current',
        fullAddress: location.address ?? 'Current Location',
        lat: location.lat,
        lng: location.lng,
        geohash: '',
        isDefault: false,
        createdAt: null,
      );

      ref.read(selectedAddressProvider.notifier).state = selected!;
      if (selected.id != 'temp') {
  await saveLastUsedAddressId(selected.id);
}

      _log.i('[Location] Initialised');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ── Provider ─────────────────────────
final locationNotifierProvider =
    AsyncNotifierProvider<LocationNotifier, UserLocation>(
  LocationNotifier.new,
);