// =============================================================
// lib/features/home/presentation/screens/home_screen.dart
// ARCHITECTURAL FINAL FIX: Zero-Sliver Conflict & Industrial Bold Logo
// Principal Architect: Laksh/Yogesh (Biteo CTO Office)
// =============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../address/presentation/providers/address_providers.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/welcome_modal.dart';
import '../../../cart/presentation/providers/cart_state.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../providers/home_providers.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/pure_veg_toggle.dart';
import '../widgets/shimmer_vendor_card.dart';
import '../widgets/vendor_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabAnimCtrl;

  @override
void initState() {
  super.initState();

  _fabAnimCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

WidgetsBinding.instance.addPostFrameCallback((_) {
  _checkWelcomeModal();

  final locationNotifier =
      ref.read(locationNotifierProvider.notifier);

  // ❌ DO NOT await → prevents UI freeze + race issues
  locationNotifier.initialise(ref);

  _fabAnimCtrl.forward();
});
}

  @override
  void dispose() {
    _fabAnimCtrl.dispose();
    super.dispose();
  }

  void _checkWelcomeModal() {
  final authState = ref.read(authNotifierProvider);

  if (authState is AuthAuthenticated) {
    if (authState.isNewUser && !authState.user.hasSeenWelcomeModal) {
      WelcomeModal.show(context, () {
        Navigator.of(context).pop();
        ref
            .read(authNotifierProvider.notifier)
            .markWelcomeModalSeen(authState.user.uid);
      });
    }
  }
}

 String? get _userName {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthAuthenticated) {
    return authState.user.fullName;
  }
  return null;
}

  // 🔥 ADD THIS BELOW
String _getGreeting() {
  final hour = DateTime.now().hour;

  if (hour < 12) {
    return "Good morning";
  } else if (hour < 17) {
    return "Good afternoon";
  } else {
    return "Good evening";
  }
}

  @override
  Widget build(BuildContext context) {
    final filteredVendors = ref.watch(filteredVendorsProvider);
    final locationAsync = ref.watch(locationNotifierProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.electricCoral,
onRefresh: () async {
  HapticFeedback.mediumImpact();

  // 🔥 clear providers
  ref.invalidate(locationNotifierProvider);
  ref.invalidate(nearbyVendorsProvider);
  ref.invalidate(filteredVendorsProvider);

  // 🔥 reinitialize location
  await ref
      .read(locationNotifierProvider.notifier)
      .initialise(ref);
},
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── 1: INDUSTRIAL BOLT LOGO (EXACT MATCH SCREENSHOT 2) ──
            SliverToBoxAdapter(
  child: SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // LOGO
          Text(
            'biteo',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF4B3A),
              letterSpacing: -0.8,
              height: 1.0,
            ),
          ),

          // ACTIONS
          Row(
            children: [
              IconButton(
                onPressed: () {
                  context.push(AppRoutes.notifications);
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 30,
                  color: AppColors.deepCharcoal,
                ),
              ),
              const SizedBox(width: 4),

              GestureDetector(
                onTap: () {
                  context.push(AppRoutes.profile);
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFFD6D2),
                  child: Text(
                    (_userName != null && _userName!.isNotEmpty)
                    ? _userName!.trim()[0].toUpperCase()
                        : 'Dear',
                    style: const TextStyle(
                      color: Color(0xFFFF4B3A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),
            // ── 2: CLICKABLE LOCATION (GUARANTEED TAP FEEDBACK) ──
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getGreeting()}${_userName != null && _userName!.isNotEmpty ? ', $_userName' : ''} 👋',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.grey500,
          ),
        ),
        const SizedBox(height: 8),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.heavyImpact();
              context.push('/location-search');
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.electricCoral,
                    size: 22,
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: locationAsync.when(
                      data: (location) {
                        if (selectedAddress != null &&
                            selectedAddress.fullAddress.trim().isNotEmpty) {
                          return Text(
                            selectedAddress.fullAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepCharcoal,
                            ),
                          );
                        }

                        final city = location.city?.trim() ?? '';
                        final state = location.state?.trim() ?? '';

                        String displayText;

                        if (city.isNotEmpty && state.isNotEmpty) {
                          displayText = '$city, $state';
                        } else if (city.isNotEmpty) {
                          displayText = city;
                        } else if (state.isNotEmpty) {
                          displayText = state;
                        } else {
                          displayText = 'Select location';
                        }

                        return Text(
                          displayText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepCharcoal,
                          ),
                        );
                      },
                      loading: () => const Text('Detecting location...'),
                      error: (_, __) => const Text('Select location'),
                    ),
                  ),

                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.grey600,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _SearchBar(),
              ),
            ),

            SliverToBoxAdapter(child: _FilterBar()),

            SliverToBoxAdapter(
              child: _SectionHeader(vendorsAsync: filteredVendors),
            ),

            // ── 3: THE ANTI-CRASH SLIVER PROTOCOL (100% SLIVER COMPLIANT) ──
            filteredVendors.when(
              // Box -> Sliver wrapper
              loading: () => SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) => const ShimmerVendorCard(),
    childCount: 5,
  ),
),
              // CRITICAL: EmptyStateWidget handles its own Sliver/Box logic
             error: (error, _) => SliverFillRemaining(
  hasScrollBody: false,
  child: EmptyStateWidget(
    type: (error is LocationFailure)
    ? EmptyStateType.locationError
    : EmptyStateType.generic,
    error: error,
    onRetry: () => ref.invalidate(locationNotifierProvider),
  ),
),
              
data: (vendors) {
  if (vendors.isEmpty) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: EmptyStateWidget(
        type: EmptyStateType.noVendors,
        onRetry: () => ref.invalidate(locationNotifierProvider),
      ),
    );
  }

  // ✅ Separate open & closed vendors
  final openVendors =
      vendors.where((v) => v.isCurrentlyOpen).toList();

  final closedVendors =
      vendors.where((v) => !v.isCurrentlyOpen).toList();

  // ✅ Mixed UI list
  final items = <dynamic>[];

  // Open restaurants
  items.addAll(openVendors);

  // Closed divider
  if (closedVendors.isNotEmpty) {
    items.add('CLOSED_DIVIDER');
    items.addAll(closedVendors);
  }

  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        final item = items[index];

        // ✅ Closed restaurants divider
        if (item == 'CLOSED_DIVIDER') {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.grey300,
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'CLOSED RESTAURANTS',
                    style:
                        AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey500,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppColors.grey300,
                    thickness: 1,
                  ),
                ),
              ],
            ),
          );
        }

        final vendor = item;

        return VendorCard(
          vendor: vendor,
          onTap: () => context.push(
            '/vendor/${vendor.id}',
            extra: vendor,
          ),
        );
      },
      childCount: items.length,
    ),
  );
},
), // ✅ THIS WAS MISSING

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── SearchBar, FilterBar, Chip, and SectionHeader logic remains same (Keep below) ──

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey100,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/search'); // ✅ open search screen
        },
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  color: AppColors.grey500, size: 20),
              const SizedBox(width: 10),
              Text(
                'Search restaurants, cuisines…',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.grey400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(vendorCategoryProvider);
    final categories = [
      {'label': 'All', 'value': 'All'},
      {'label': 'Cafes ☕', 'value': 'Cafe'},
      {'label': 'Bakery 🥐', 'value': 'Bakery'},
      {'label': 'Meals 🍱', 'value': 'Meal'},
      {'label': 'Desserts 🍰', 'value': 'Dessert'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const PureVegToggle(),
          const SizedBox(width: 10),
          ...categories.map((cat) {
            final isSelected = selectedCategory == cat['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: cat['label']!,
                isSelected: isSelected,
                onTap: () => ref.read(vendorCategoryProvider.notifier).setCategory(cat['value']!),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricCoral : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.electricCoral : AppColors.grey200),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.grey700,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final AsyncValue<dynamic> vendorsAsync;
  const _SectionHeader({required this.vendorsAsync});

  @override
  Widget build(BuildContext context) {
    final count = vendorsAsync.maybeWhen(
      data: (list) => list.length as int,
      orElse: () => null,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 8),
      child: Row(
        children: [
          Text('Nearby Restaurants', style: AppTextStyles.headlineMedium),
          if (count != null && count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.electricCoral.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.electricCoral,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}