import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/address_providers.dart';

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(localAddressListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Addresses"),
      ),
      body: addresses.isEmpty
          ? const Center(
              child: Text("No saved addresses yet"),
            )
          : ListView.builder(
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final addr = addresses[index];

                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(addr.fullAddress),
                  subtitle: Text(addr.label),
                );
              },
            ),
    );
  }
}