// ============================================================
// lib/features/address/presentation/providers/address_state.dart
// ============================================================

class MapPinState {
  final double lat;
  final double lng;
  final String displayAddress;
  final bool isGeocoding;
  final bool isSearching;
  final bool isConfirmed;

  const MapPinState({
    required this.lat,
    required this.lng,
    this.displayAddress = '',
    this.isGeocoding = false,
    this.isSearching = false,
    this.isConfirmed = false,
  });

  MapPinState copyWith({
    double? lat,
    double? lng,
    String? displayAddress,
    bool? isGeocoding,
    bool? isSearching,
    bool? isConfirmed,
  }) {
    return MapPinState(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      displayAddress: displayAddress ?? this.displayAddress,
      isGeocoding: isGeocoding ?? this.isGeocoding,
      isSearching: isSearching ?? this.isSearching,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

sealed class AddressSaveState {
  const AddressSaveState();
}

final class AddressSaveIdle extends AddressSaveState {
  const AddressSaveIdle();
}

final class AddressSaveLoading extends AddressSaveState {
  const AddressSaveLoading();
}

final class AddressSaveSuccess extends AddressSaveState {
  const AddressSaveSuccess();
}

final class AddressSaveError extends AddressSaveState {
  final String message;
  const AddressSaveError(this.message);
}
