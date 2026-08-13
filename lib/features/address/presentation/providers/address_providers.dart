// ============================================================
// lib/features/address/presentation/providers/address_providers.dart
// FINAL CLEAN VERSION (PRODUCTION SAFE)
// ============================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/auth/presentation/providers/auth_state.dart';
import '../../data/repositories/address_repository_impl.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/i_address_repository.dart';
import 'address_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

// ============================================================
// REPOSITORY
// ============================================================
final addressRepositoryProvider = Provider<IAddressRepository>(
  (_) => AddressRepositoryImpl(),
);

// ============================================================
// FIRESTORE STREAM (KEEP FOR FUTURE)
// ============================================================
final savedAddressesProvider =
    StreamProvider.autoDispose<List<AddressEntity>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) return Stream.value([]);

  return ref
      .watch(addressRepositoryProvider)
      .watchAddresses(authState.user.uid);
});

// ============================================================
// SELECTED ADDRESS (FIX ADDED HERE ✅)
// ============================================================
class SelectedAddressNotifier extends Notifier<AddressEntity?> {
  @override
  AddressEntity? build() {
    ref.listen<AsyncValue<List<AddressEntity>>>(
      savedAddressesProvider,
      (_, next) {
        next.whenData((addresses) {
          // ❌ No addresses → clear state
          if (addresses.isEmpty) {
            state = null;
            return;
          }

        final authState = ref.read(authNotifierProvider);

String? lastId;

if (authState is AuthAuthenticated) {
  lastId = authState.user.lastAddressId;
}

          // ✅ If current state is still valid → keep it
          if (state != null &&
              addresses.any((a) => a.id == state!.id)) {
            return;
          }

          // ✅ Try last used address
          if (lastId != null) {
            final match =
                addresses.where((a) => a.id == lastId).toList();

            if (match.isNotEmpty) {
              state = match.first;
              return;
            }
          }

          // ✅ Fallback to default or first
          final def =
              addresses.where((a) => a.isDefault).toList();

          state = def.isNotEmpty ? def.first : addresses.first;
        });
      },
    );

    return null;
  }

  void select(AddressEntity? address) async {
    // ✅ Prevent unnecessary updates
    if (state?.id == address?.id) return;

    state = address;

    // 🔥 SAVE LAST USED ADDRESS
    try {
      final authState = ref.read(authNotifierProvider);

      if (authState is AuthAuthenticated && address != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authState.user.uid)
            .update({
          "last_address_id": address.id,
        });

        _log.i('[Address] Saved last used address');
      }
    } catch (e) {
      _log.e('[Address] Failed to save last address', error: e);
    }
  }

  void clear() => state = null;
}

// 🔥 PROVIDER
final selectedAddressProvider =
    NotifierProvider<SelectedAddressNotifier, AddressEntity?>(
        SelectedAddressNotifier.new);

// ============================================================
// LOCAL LIST (INSTANT UI UPDATE)
// ============================================================
final localAddressListProvider =
    NotifierProvider<LocalAddressListNotifier, List<AddressEntity>>(
  LocalAddressListNotifier.new,
);

class LocalAddressListNotifier extends Notifier<List<AddressEntity>> {
  @override
  List<AddressEntity> build() => [];
}
// ============================================================
// MAP PIN STATE
// ============================================================
class MapPinNotifier extends Notifier<MapPinState> {
  Timer? _debounce;

  @override
  MapPinState build() {
    ref.onDispose(() => _debounce?.cancel());

    return const MapPinState(
      lat: 28.4595,
      lng: 77.0266,
      displayAddress: 'Tap to set location',
    );
  }

  void initialise(double lat, double lng) {
    state = state.copyWith(
      lat: lat,
      lng: lng,
      isGeocoding: true,
    );
    _reverseGeocode(lat, lng);
  }

  void onCameraIdle(double lat, double lng) {
    state = state.copyWith(
      lat: lat,
      lng: lng,
      isGeocoding: true,
      isConfirmed: false,
    );

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(lat, lng);
    });
  }

  Future<LatLng?> searchAddress(String query) async {
    if (query.trim().isEmpty) return null;

    state = state.copyWith(isSearching: true);

    try {
      final locations = await locationFromAddress(query.trim());

      if (locations.isNotEmpty) {
        final loc = locations.first;

        state = state.copyWith(
          lat: loc.latitude,
          lng: loc.longitude,
          isSearching: false,
        );

        return LatLng(loc.latitude, loc.longitude);
      }
    } catch (e) {
      _log.e('[MapPin] Search error', error: e);
    }

    state = state.copyWith(isSearching: false);
    return null;
  }

  void confirm() {
    state = state.copyWith(isConfirmed: true);
  }

  void resetConfirm() {
    state = state.copyWith(isConfirmed: false);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final parts = <String>[
          if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
          if ((p.locality ?? '').isNotEmpty) p.locality!,
          if ((p.administrativeArea ?? '').isNotEmpty)
            p.administrativeArea!,
        ];

        final address =
            parts.take(2).join(', ').trim().isNotEmpty
                ? parts.take(2).join(', ')
                : 'Unknown location';

        state = state.copyWith(
          displayAddress: address,
          isGeocoding: false,
        );

        return;
      }
    } catch (e) {
      _log.e('[MapPin] Reverse geocode error', error: e);
    }

    state = state.copyWith(
      displayAddress: 'Unknown location',
      isGeocoding: false,
    );
  }
}

final mapPinProvider =
    NotifierProvider<MapPinNotifier, MapPinState>(
        MapPinNotifier.new);

        // ADDRESS ACTIONS (DELETE)
// ============================================================
class AddressActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> deleteAddress(String addressId) async {
    final authState = ref.read(authNotifierProvider);

    if (authState is! AuthAuthenticated) return;

    state = const AsyncLoading();

    final result = await ref
        .read(addressRepositoryProvider)
        .deleteAddress(
          userId: authState.user.uid,
          addressId: addressId,
        );

    result.fold(
      (failure) {
        state = AsyncError(failure.userMessage, StackTrace.current);
      },
      (_) {
        state = const AsyncData(null);

        ref.invalidate(savedAddressesProvider);

        ref.read(localAddressListProvider.notifier).state =
            ref.read(localAddressListProvider)
                .where((a) => a.id != addressId)
                .toList();
      },
    );
  }
}

final addressActionProvider =
    NotifierProvider<AddressActionNotifier, AsyncValue<void>>(
  AddressActionNotifier.new,
);

// ============================================================
// SAVE ADDRESS
// ============================================================
class AddressSaveNotifier extends Notifier<AddressSaveState> {
// SAVE ADDRESS
// ============================================================
  @override
  AddressSaveState build() => const AddressSaveIdle();

  Future<AddressEntity?> save({
    String? id,
    required String label,
    required String fullAddress,
    required double lat,
    required double lng,
    required String geohash,
    String? flatHouseNo,
    String? floor,
    String? landmark,
    String? buildingName,
    String? contactName,
    String? contactPhone,
    bool isDefault = false,
  }) async {
    final authState = ref.read(authNotifierProvider);

    if (authState is! AuthAuthenticated) return null;

    state = const AddressSaveLoading();

final address = AddressEntity(
  id: id != null && id.isNotEmpty ? id : const Uuid().v4(),
      label: label,
      fullAddress: fullAddress,
      flatHouseNo: flatHouseNo,
      floor: floor,
      landmark: landmark,
      buildingName: buildingName,
      lat: lat,
      lng: lng,
      geohash: geohash,
      isDefault: isDefault,
      contactName: contactName,
      contactPhone: contactPhone,
      createdAt: DateTime.now(),
    );

    final result = await ref
        .read(addressRepositoryProvider)
        .saveAddress(
          userId: authState.user.uid,
          address: address,
        );

    return result.fold(
      (failure) {
        _log.e("SAVE ERROR: ${failure.userMessage}");
        state = AddressSaveError(failure.userMessage);
        return null;
      },
      (saved) {
        state = const AddressSaveSuccess();

        // ✅ select current address
        ref.read(selectedAddressProvider.notifier).select(saved);

        // ✅ instant UI update (CRITICAL)
       final list = ref.read(localAddressListProvider);

ref.read(localAddressListProvider.notifier).state = [
  saved,
  ...list.where((a) => a.id != saved.id),
];

        return saved;
      },
    );
  }

  void reset() => state = const AddressSaveIdle();
}

final addressSaveProvider =
    NotifierProvider<AddressSaveNotifier, AddressSaveState>(
  AddressSaveNotifier.new,
);

// ============================================================
// SIMPLE GEOHASH
// ============================================================
String computeSimpleGeohash(double lat, double lng) {
  final latStr = (lat * 1000).round().toString().replaceAll('-', 'n');
  final lngStr = (lng * 1000).round().toString().replaceAll('-', 'n');
  return '${latStr}_$lngStr';
}