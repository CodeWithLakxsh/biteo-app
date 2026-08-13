import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/address_providers.dart';
import '../widgets/address_save_form_sheet.dart';
import 'map_location_screen.dart';

class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(savedAddressesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Saved Addresses"),
        centerTitle: true,
      ),
      body: addressesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),

        error: (e, _) =>
            const Center(child: Text("Failed to load addresses")),

        data: (addresses) {
          if (addresses.isEmpty) {
            return const Center(child: Text("No saved addresses"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];

              return GestureDetector(
                onTap: () {
                  ref
                      .read(selectedAddressProvider.notifier)
                      .select(address);

                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.electricCoral,
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          address.fullAddress,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ EDIT (FIXED)
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blue),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MapLocationScreen(
                                    initialLat: address.lat,
                                    initialLng: address.lng,
                                  ),
                                ),
                              );

                              if (result != null) {
                                await AddressSaveFormSheet.show(
                                  context,
                                  lat: result.lat,              // ✅ FIX
                                  lng: result.lng,              // ✅ FIX
                                  fullAddress: result.address,  // ✅ FIX
                                  geohash: result.geohash,      // ✅ FIX
                                  existingAddress: address,     // ✅ KEEP SAME ID
                                );
                              }
                            },
                          ),

                          // ✅ DELETE
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () {
                              ref
                                  .read(addressActionProvider.notifier)
                                  .deleteAddress(address.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}