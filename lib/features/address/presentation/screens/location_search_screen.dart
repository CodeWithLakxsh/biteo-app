import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/location_provider.dart';
import '../../data/services/places_service.dart';
import 'map_location_screen.dart';
import '../providers/address_providers.dart';
import '../widgets/address_save_form_sheet.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';

class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  ConsumerState<LocationSearchScreen> createState() =>
      _LocationSearchScreenState();
}

class _LocationSearchScreenState
    extends ConsumerState<LocationSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  List<String> suggestions = [];
  bool isLoading = false;

  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.isEmpty) {
        if (mounted) setState(() => suggestions = []);
        return;
      }

      setState(() => isLoading = true);

      final result = await PlacesService.getSuggestions(value);

      if (!mounted) return;

      setState(() {
        suggestions = result;
        isLoading = false;
      });
    });
  }

  Future<void> _openMapFromPlace(String place) async {
    final location = await PlacesService.getPlaceDetails(place);

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not found")),
      );
      return;
    }

    if (!mounted) return;

    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationScreen(
          initialLat: location.lat,
          initialLng: location.lng,
        ),
      ),
    );
  }

  Future<void> _openFromCurrentLocation() async {
    final loc = await ref
        .read(locationNotifierProvider.notifier)
        .future;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationScreen(
          initialLat: loc.lat,
          initialLng: loc.lng,
        ),
      ),
    );
  }

  void _openEmptyMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapLocationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.value.text;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: SizedBox(
          height: 42,
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Search location...",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
      body: query.isEmpty
          ? _buildDefaultOptions()
          : isLoading
              ? const Center(child: CircularProgressIndicator())
              : suggestions.isEmpty
                  ? const Center(child: Text("No results found"))
                  : ListView.builder(
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final place = suggestions[index];

                        return ListTile(
                          leading:
                              const Icon(Icons.location_on_outlined),
                          title: Text(place),
                          onTap: () {
                            _openMapFromPlace(place);
                          },
                        );
                      },
                    ),
    );
  }

  Widget _buildDefaultOptions() {
    final savedAddressesAsync = ref.watch(savedAddressesProvider);

    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.my_location),
          title: const Text("Use current location"),
          onTap: _openFromCurrentLocation,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.map_outlined),
          title: const Text("Select location on map"),
          onTap: _openEmptyMap,
        ),
        const Divider(),

        if (savedAddressesAsync.hasValue &&
            savedAddressesAsync.value!.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Saved Addresses",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

        ...savedAddressesAsync.when(
          data: (savedAddresses) => savedAddresses.map((address) {
            return ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(address.label),
              subtitle: Text(address.fullAddress),

              // ✅ FIX APPLIED HERE
              onTap: () {
                ref
                    .read(selectedAddressProvider.notifier)
                    .select(address);

                ref.read(locationNotifierProvider.notifier)
                    .saveLastUsedAddressId(address.id);

                Navigator.pop(context);
              },

              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    final authState = ref.read(authNotifierProvider);

                    if (authState is AuthAuthenticated) {
                      await ref
                          .read(addressRepositoryProvider)
                          .deleteAddress(
                            userId: authState.user.uid,
                            addressId: address.id,
                          );
                    }
                  } else if (value == 'edit') {
                    if (!mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapLocationScreen(
                          initialLat: address.lat,
                          initialLng: address.lng,
                          existingAddress: address,
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            );
          }).toList(),

          loading: () => [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          ],

          error: (_, __) => [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Error loading addresses"),
            )
          ],
        ),
      ],
    );
  }
}