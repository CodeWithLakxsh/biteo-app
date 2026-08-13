// ============================================================
// lib/features/address/presentation/screens/map_location_screen.dart
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/address_providers.dart';
import '../providers/address_state.dart';
import '../widgets/address_save_form_sheet.dart';
import '../../domain/entities/address_entity.dart';
import '../../../../core/services/places_service.dart';

class MapLocationScreen extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLng;

 final AddressEntity? existingAddress;

const MapLocationScreen({
  super.key,
  this.initialLat,
  this.initialLng,
  this.existingAddress, // ✅ ADD THIS
});

  @override
  ConsumerState<MapLocationScreen> createState() =>
      _MapLocationScreenState();
}

class _MapLocationScreenState extends ConsumerState<MapLocationScreen> {
  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _mapController;

  double _centerLat = 28.4595;
  double _centerLng = 77.0266;
  bool _mapMoving = false;

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  List<String> _suggestions = [];
bool _isSearchingPlaces = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromGps();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _initFromGps() {
  // 🔥 1. EDIT MODE (from profile saved address)
  if (widget.existingAddress != null) {
    _centerLat = widget.existingAddress!.lat;
    _centerLng = widget.existingAddress!.lng;

    ref.read(mapPinProvider.notifier).initialise(
      _centerLat,
      _centerLng,
    );

    setState(() {});

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_centerLat, _centerLng),
            zoom: 15,
          ),
        ),
      );
    }
    return;
  }

  // 🔥 2. SEARCH LOCATION
  if (widget.initialLat != null && widget.initialLng != null) {
    _centerLat = widget.initialLat!;
    _centerLng = widget.initialLng!;

    ref.read(mapPinProvider.notifier).initialise(
      _centerLat,
      _centerLng,
    );

    setState(() {});

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_centerLat, _centerLng),
            zoom: 15,
          ),
        ),
      );
    }
    return;
  }

  // 🔥 3. DEFAULT → GPS
  final locationAsync = ref.read(locationNotifierProvider);

  locationAsync.whenData((loc) {
    if (!mounted) return;

    _centerLat = loc.lat;
    _centerLng = loc.lng;

    ref.read(mapPinProvider.notifier).initialise(
      loc.lat,
      loc.lng,
    );

    setState(() {});

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(loc.lat, loc.lng),
            zoom: 15,
          ),
        ),
      );
    }
  });
}
  Future<void> _onSearch(String query) async {
    FocusScope.of(context).unfocus();

    final result =
        await ref.read(mapPinProvider.notifier).searchAddress(query);

    if (result != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: result,
            zoom: 15,
          ),
        ),
      );
    } else if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location not found. Try a more specific search.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

Future<void> _onConfirm() async {
 HapticFeedback.mediumImpact();
FocusScope.of(context).unfocus();

  final pinState = ref.read(mapPinProvider);

  final savedAddress = await AddressSaveFormSheet.show(
  context,
  lat: pinState.lat,
  lng: pinState.lng,
  fullAddress: pinState.displayAddress,
  geohash: "${pinState.lat},${pinState.lng}",
  existingAddress: widget.existingAddress,
);

// ✅ ONLY set if user actually saved
if (savedAddress != null) {
  // ✅ 1. Update selected address in UI
  ref.read(selectedAddressProvider.notifier).select(savedAddress);

  // ✅ 2. Save last used address ID (for restart persistence)
  await ref
      .read(locationNotifierProvider.notifier)
      .saveLastUsedAddressId(savedAddress.id);

  // ✅ 3. Sync location provider with selected address
  await ref.read(locationNotifierProvider.notifier).saveLocation(
        UserLocation(
          lat: savedAddress.lat,
          lng: savedAddress.lng,
          address: savedAddress.fullAddress,
        ),
      );
}

if (mounted) Navigator.pop(context);
}

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(mapPinProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_centerLat, _centerLng),
              zoom: 15,
            ),

            // ✅ Smooth zoom limits
            minMaxZoomPreference:
                const MinMaxZoomPreference(10, 17),

            // ✅ FULL FREE MOVEMENT
            cameraTargetBounds: CameraTargetBounds.unbounded,

            onMapCreated: (controller) {
  _mapController = controller;

  if (!_mapCompleter.isCompleted) {
    _mapCompleter.complete(controller);
  }

  // 🔥 Ensure camera moves after map loads
  _initFromGps();
},

            onCameraMove: (position) {
              _centerLat = position.target.latitude;
              _centerLng = position.target.longitude;

              // ✅ Smooth zoom correction (no jitter)
              if (position.zoom < 10 && _mapController != null) {
                _mapController!.moveCamera(
                  CameraUpdate.zoomTo(10),
                );
              }

              if (!_mapMoving) {
                setState(() => _mapMoving = true);
              }
            },

            onCameraIdle: () {
              if (!mounted) return;

              setState(() => _mapMoving = false);

              ref
                  .read(mapPinProvider.notifier)
                  .onCameraIdle(_centerLat, _centerLng);
            },

            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            padding: const EdgeInsets.only(bottom: 160),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: _AnimatedPin(isMoving: _mapMoving),
              ),
            ),
          ),

          Positioned(
  top: 0,
  left: 0,
  right: 0,
  child: SafeArea(
    child: Container(
      margin: const EdgeInsets.all(12),
      child: _SearchBar(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        onSearch: _onSearch,
        isSearching: _isSearchingPlaces,
        onChanged: (value) async {
          if (value.trim().isEmpty) {
            setState(() => _suggestions = []);
            return;
          }

          setState(() => _isSearchingPlaces = true);

          final results = await PlacesService.getSuggestions(value);

          if (!mounted) return;

          setState(() {
            _suggestions = results;
            _isSearchingPlaces = false;
          });
        },
      ),
    ),
  ),
),

// 🔥👇 ADD THIS BLOCK RIGHT HERE 👇🔥
if (_suggestions.isNotEmpty)
  Positioned(
    top: 80,
    left: 12,
    right: 12,
    child: Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final place = _suggestions[index];

          return ListTile(
            title: Text(place),
            onTap: () async {
              final location =
                  await PlacesService.getPlaceDetails(place);

              if (location != null && _mapController != null) {
                await _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(location.lat, location.lng),
                      zoom: 15,
                    ),
                  ),
                );

                ref.read(mapPinProvider.notifier).initialise(
                      location.lat,
                      location.lng,
                    );

                setState(() {
                  _searchCtrl.text = place;
                  _suggestions = [];
                });
              }
            },
          );
        },
      ),
    ),
  ),
// 🔥👆 END HERE 👆🔥

Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: _ConfirmBar(
              pinState: pinState,
              onConfirm: _onConfirm,
              onMyLocation: () async {
  HapticFeedback.selectionClick();

  final loc = await ref
      .read(locationNotifierProvider.notifier)
      .future;

  if (!mounted || _mapController == null) return;

  _centerLat = loc.lat;
  _centerLng = loc.lng;

  await _mapController!.animateCamera(
    CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(loc.lat, loc.lng),
        zoom: 15,
      ),
    ),
  );

  ref
      .read(mapPinProvider.notifier)
      .initialise(loc.lat, loc.lng);
},
            ),
          ),
        ],
      ),
    );
  }
}
class _AnimatedPin extends StatelessWidget {
  final bool isMoving;
  const _AnimatedPin({required this.isMoving});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform:
              Matrix4.translationValues(0, isMoving ? -12 : 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.electricCoral,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.electricCoral.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              Container(
                width: 2.5,
                height: 16,
                color: AppColors.electricCoral,
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isMoving ? 20 : 12,
          height: isMoving ? 6 : 4,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSearch;
  final bool isSearching;
  final ValueChanged<String>? onChanged;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onSearch,
    required this.isSearching,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.deepCharcoal,
                ),
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: AppTextStyles.bodyLarge,
                textInputAction: TextInputAction.search,
                onSubmitted: onSearch,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Search for area, street name…',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey400),
                  filled: true,
                  fillColor: AppColors.grey100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.grey200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.electricCoral,
                      width: 1.5,
                    ),
                  ),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.electricCoral,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.grey500,
                            size: 20,
                          ),
                          onPressed: () =>
                              onSearch(controller.text),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ConfirmBar extends StatelessWidget {
  final MapPinState pinState;
  final VoidCallback onConfirm;
  final VoidCallback onMyLocation;

  const _ConfirmBar({
    required this.pinState,
    required this.onConfirm,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.electricCoral.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppColors.electricCoral, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pinState.isGeocoding)
                      Container(
                        height: 14,
                        width: 180,
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    else
                      Text(
                        pinState.displayAddress,
                        style: AppTextStyles.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Move the map to adjust pin',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onMyLocation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    size: 20,
                    color: AppColors.deepCharcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: pinState.isGeocoding ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricCoral,
              disabledBackgroundColor:
                  AppColors.electricCoral.withOpacity(0.5),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              shadowColor: AppColors.electricCoral.withOpacity(0.35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Confirm this Location',
                    style: AppTextStyles.labelLarge),
                const SizedBox(width: 8),
                const Icon(Icons.check_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
