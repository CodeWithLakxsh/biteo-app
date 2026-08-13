// ============================================================
// lib/features/address/presentation/widgets/address_save_form_sheet.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/address_providers.dart';
import '../providers/address_state.dart';
import '../../domain/entities/address_entity.dart';

class AddressSaveFormSheet extends ConsumerStatefulWidget {
  final double lat;
  final double lng;
  final String fullAddress;
  final String geohash;

  final AddressEntity? existingAddress;

  const AddressSaveFormSheet({
    super.key,
    required this.lat,
    required this.lng,
    required this.fullAddress,
    required this.geohash,
    this.existingAddress,
  });

  static Future<AddressEntity?> show(
    BuildContext context, {
    required double lat,
    required double lng,
    required String fullAddress,
    required String geohash,
    AddressEntity? existingAddress,
  }) async {
    return await showModalBottomSheet<AddressEntity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return AddressSaveFormSheet(
          lat: lat,
          lng: lng,
          fullAddress: fullAddress,
          geohash: geohash,
          existingAddress: existingAddress,
        );
      },
    );
  }

  @override
  ConsumerState<AddressSaveFormSheet> createState() =>
      _AddressSaveFormSheetState();
}

class _AddressSaveFormSheetState
    extends ConsumerState<AddressSaveFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String _selectedLabel = 'home';

  final _flatCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _otherLabelCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _flatFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _prefillContact();

    // 🔥 FINAL FIX: PREFILL WHEN EDITING
    if (widget.existingAddress != null) {
      final a = widget.existingAddress!;

      _selectedLabel = a.label;

      _flatCtrl.text = a.flatHouseNo ?? '';
      _floorCtrl.text = a.floor ?? '';
      _landmarkCtrl.text = a.landmark ?? '';
      _buildingCtrl.text = a.buildingName ?? '';
      _nameCtrl.text = a.contactName ?? '';
      _phoneCtrl.text = a.contactPhone ?? '';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _flatFocus.requestFocus();
      });
    });
  }

  void _prefillContact() {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      _nameCtrl.text = authState.user.fullName ?? '';
      _phoneCtrl.text = authState.user.phone.replaceAll('+91', '');
    }
  }

  @override
  void dispose() {
    _flatCtrl.dispose();
    _floorCtrl.dispose();
    _landmarkCtrl.dispose();
    _otherLabelCtrl.dispose();
    _buildingCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _flatFocus.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    final saved = await ref.read(addressSaveProvider.notifier).save(
      id: widget.existingAddress?.id,
      label: _selectedLabel == 'other'
          ? _otherLabelCtrl.text.trim()
          : _selectedLabel,
      fullAddress: widget.fullAddress,
      lat: widget.lat,
      lng: widget.lng,
      geohash: widget.geohash,
      flatHouseNo: _flatCtrl.text.trim(),
      floor: _floorCtrl.text.trim().isEmpty
          ? null
          : _floorCtrl.text.trim(),
      landmark: _landmarkCtrl.text.trim().isEmpty
          ? null
          : _landmarkCtrl.text.trim(),
      buildingName: _buildingCtrl.text.trim().isEmpty
          ? null
          : _buildingCtrl.text.trim(),
      contactName: _nameCtrl.text.trim(),
      contactPhone: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;

    if (saved != null) {
      final parts = widget.fullAddress.split(',');

      String? city;
      String? state;

      if (parts.length >= 3) {
        city = parts[parts.length - 3].trim();
        state = parts[parts.length - 2].trim();

        if (city.isEmpty) city = null;
        if (state.isEmpty) state = null;
      } else if (parts.length >= 2) {
        city = parts[parts.length - 2].trim();
        state = parts.last.trim();
      }

      ref.read(locationNotifierProvider.notifier).saveLocation(
            UserLocation(
              lat: widget.lat,
              lng: widget.lng,
              city: city,
              state: state,
              address: widget.fullAddress,
            ),
          );

      ref.invalidate(locationNotifierProvider);
     ref.read(selectedAddressProvider.notifier).select(saved);
Navigator.pop(context, saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(addressSaveProvider);
    final isLoading = saveState is AddressSaveLoading;

    ref.listen<AddressSaveState>(addressSaveProvider, (_, next) {
      if (next is AddressSaveError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(next.message,
                style:
                    AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.error,
            margin: const EdgeInsets.all(16),
          ));
      }
    });

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 👇 REST OF YOUR UI EXACT SAME (UNCHANGED)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.electricCoral.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.electricCoral.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.electricCoral, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.fullAddress,
                          style: AppTextStyles.bodySmall
                              .copyWith(height: 1.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Save address as',
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
               _LabelSelector(
  selected: _selectedLabel,
  onChanged: (v) => setState(() => _selectedLabel = v),
),

// ✅ ADD THIS BLOCK HERE
if (_selectedLabel == 'other') ...[
  const SizedBox(height: 12),
  TextFormField(
    controller: _otherLabelCtrl,
    decoration: const InputDecoration(
      hintText: "Enter custom label (e.g. Gym, Friend's home)",
    ),
    validator: (v) {
      if (_selectedLabel == 'other' &&
          (v == null || v.trim().isEmpty)) {
        return 'Please enter a label';
      }
      return null;
    },
  ),
],

const SizedBox(height: 20),

Text('Flat / House No.*',
  style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _flatCtrl,
                  focusNode: _flatFocus,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.words,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'e.g. B-204',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Flat/House number is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Building / Society',
                              style: AppTextStyles.titleMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _buildingCtrl,
                            enabled: !isLoading,
                            textCapitalization:
                                TextCapitalization.words,
                            style: AppTextStyles.bodyLarge,
                            decoration: const InputDecoration(
                              hintText: 'e.g. DLF Tower',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Floor',
                              style: AppTextStyles.titleMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _floorCtrl,
                            enabled: !isLoading,
                            style: AppTextStyles.bodyLarge,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 3rd',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Nearby Landmark',
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _landmarkCtrl,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Near Starbucks, Cyber Hub',
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Text('Your contact details',
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'So the restaurant can call you if needed.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.words,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        size: 20, color: AppColors.grey500),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  enabled: !isLoading,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: '10-digit mobile number',
                    prefixIcon: Icon(Icons.phone_outlined,
                        size: 20, color: AppColors.grey500),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 10) {
                      return 'Valid 10-digit number required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: isLoading ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricCoral,
                    minimumSize: const Size(double.infinity, 56),
                    disabledBackgroundColor:
                        AppColors.electricCoral.withOpacity(0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: isLoading ? 0 : 3,
                    shadowColor:
                        AppColors.electricCoral.withOpacity(0.35),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Save Address',
                                style: AppTextStyles.labelLarge),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _LabelSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _labels = [
    (value: 'home', icon: Icons.home_rounded, text: 'Home'),
    (value: 'work', icon: Icons.work_rounded, text: 'Work'),
    (value: 'other', icon: Icons.location_on_rounded, text: 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _labels
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(item.value);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected == item.value
                          ? AppColors.electricCoral
                          : AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected == item.value
                            ? AppColors.electricCoral
                            : AppColors.grey200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: selected == item.value
                              ? Colors.white
                              : AppColors.grey600,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.text,
                          style: AppTextStyles.caption.copyWith(
                            color: selected == item.value
                                ? Colors.white
                                : AppColors.grey700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
