// ============================================================
// lib/features/vendor/presentation/screens/vendor_detail_screen.dart
// Premium Vendor Detail Screen with parallax header,
// sticky category tabs, menu list, and floating cart bar.
// ============================================================
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/widgets/cart_bottom_sheet.dart';
import 'package:biteo/features/cart/presentation/providers/cart_state.dart';
import '../../../home/domain/entities/vendor_entity.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../providers/vendor_detail_providers.dart';
import '../widgets/menu_item_card.dart';

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final VendorEntity vendor;
  const VendorDetailScreen({super.key, required this.vendor});

  @override
  ConsumerState<VendorDetailScreen> createState() =>
      _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  bool _showStickyTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    // ✅ NO AUTO POPUP HERE (REMOVED)
  }

  void _onScroll() {
    final showTitle = _scrollController.offset > 220;
    if (showTitle != _showStickyTitle) {
      setState(() => _showStickyTitle = showTitle);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;
    final menuAsync = ref.watch(menuItemsProvider(vendor.id));
    final categories = ref.watch(menuCategoriesProvider(vendor.id));
    final grouped = ref.watch(groupedMenuProvider(vendor.id));
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. Parallax Cover Image AppBar ───────────────
          _VendorSliverAppBar(
            vendor: vendor,
            showTitle: _showStickyTitle,
          ),

          // ── 2. Vendor Info Card ──────────────────────────
          SliverToBoxAdapter(
            child: _VendorInfoCard(vendor: vendor),
          ),

          // ── 3. Pure Veg Toggle Row ───────────────────────
          SliverToBoxAdapter(
            child: _VegFilterRow(vendorId: vendor.id),
          ),

          // ── 4. Category Tabs (Sticky) ────────────────────
          if (categories.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryTabDelegate(
                categories: categories,
                vendorId: vendor.id,
              ),
            ),

          // ── 5. Menu Content ──────────────────────────────
          menuAsync.when(
            loading: () => _MenuShimmer(),
            error: (e, _) => SliverToBoxAdapter(
              child: _ErrorView(
                onRetry: () => ref.invalidate(menuItemsProvider(vendor.id)),
              ),
            ),
            data: (_) {
              if (grouped.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyMenu(),
                );
              }

              // Flatten grouped map into a mixed list of headers + items.
              final sliverItems = <_SliverItem>[];
              for (final entry in grouped.entries) {
                sliverItems.add(_SliverItem.header(entry.key));
                for (final item in entry.value) {
                  sliverItems.add(_SliverItem.item(item));
                }
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final si = sliverItems[i];
                    if (si.isHeader) {
                      return _CategoryHeader(category: si.header!);
                    }
                    return MenuItemCard(
  item: si.item!,
  vendorId: vendor.id,
  vendorName: vendor.businessName,
  isVendorOpen: vendor.isCurrentlyOpen,
);
                  },
                  childCount: sliverItems.length,
                ),
              );
            },
          ),

          // ── 6. FSSAI Footer ──────────────────────────────
          SliverToBoxAdapter(
            child: _FssaiFooter(vendor: vendor),
          ),

          // Bottom space for the cart bar
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),

      // ── Floating Cart Bar ─────────────────────────────────
      bottomNavigationBar: cartCount > 0 ? _FloatingCartBar(vendor: vendor) : null,
    );
  }
}

// ── Sliver Item Model ──────────────────────────────────────────
class _SliverItem {
  final bool isHeader;
  final String? header;
  final MenuItemEntity? item;

  const _SliverItem.header(this.header)
      : isHeader = true,
        item = null;

  const _SliverItem.item(this.item)
      : isHeader = false,
        header = null;
}

// ── Vendor Sliver AppBar ──────────────────────────────────────
class _VendorSliverAppBar extends StatelessWidget {
  final VendorEntity vendor;
  final bool showTitle;

  const _VendorSliverAppBar({
    required this.vendor,
    required this.showTitle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.background,

      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.deepCharcoal,
            ),
          ),
        ),
      ),

      // ✅ INFO ICON ADDED (TOP RIGHT)
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VendorInfoScreen(vendor: vendor),
                ),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.deepCharcoal,
              ),
            ),
          ),
        ),
      ],

      title: AnimatedOpacity(
        opacity: showTitle ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text(vendor.businessName, style: AppTextStyles.titleLarge),
      ),

      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image with parallax
            // ─────────────────────────────
// SAFE COVER IMAGE
// ─────────────────────────────

Builder(
  builder: (context) {
    final imageUrl =
        (vendor.coverImageUrl ?? '')
            .toString()
            .trim();

    if (imageUrl.isEmpty) {
      return _CoverPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,

      placeholder: (_, __) {
        return Container(
          color: AppColors.grey200,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.electricCoral,
              strokeWidth: 2,
            ),
          ),
        );
      },

      errorWidget: (_, __, ___) {
        return _CoverPlaceholder();
      },
    );
  },
),

            // Bottom fade gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),

            // Open/Closed badge
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: vendor.isCurrentlyOpen ? AppColors.vegGreen : AppColors.grey600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      vendor.isCurrentlyOpen ? 'Open Now' : 'Currently Closed',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.electricCoral.withOpacity(0.1),
      child: const Center(
        child: Text('🍽️', style: TextStyle(fontSize: 60)),
      ),
    );
  }
}

// ── Vendor Info Card ──────────────────────────────────────────
class _VendorInfoCard extends StatelessWidget {
  final VendorEntity vendor;
  const _VendorInfoCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + FSSAI badge row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  vendor.businessName,
                  style: AppTextStyles.headlineLarge,
                ),
              ),
              _FssaiBadge(license: vendor.fssaiLicense),
            ],
          ),

          const SizedBox(height: 8),

          // Address
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.grey500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  vendor.fullAddress,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF5A623),
                label: vendor.ratingText,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.access_time_rounded,
                iconColor: AppColors.grey500,
                label: vendor.prepTimeText,
              ),
              const SizedBox(width: 10),
              if (vendor.distanceText.isNotEmpty)
                _StatChip(
                  icon: Icons.directions_walk_rounded,
                  iconColor: AppColors.electricCoral,
                  label: vendor.distanceText,
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Tags
          if (vendor.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: vendor.tags.map((t) => _TagPill(label: t)).toList(),
            ),
        ],
      ),
    );
  }
}

class _FssaiBadge extends StatelessWidget {
  final String license;
  const _FssaiBadge({required this.license});

  @override
  Widget build(BuildContext context) {
    final lic = license.trim();
    return Tooltip(
      message: lic.isNotEmpty ? 'FSSAI License: $lic' : 'FSSAI License not available',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.vegGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.vegGreen.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 12, color: AppColors.vegGreen),
            const SizedBox(width: 4),
            Text(
              'FSSAI',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.vegGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final text = label.isEmpty ? label : label[0].toUpperCase() + label.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Veg Filter Row ────────────────────────────────────────────
class _VegFilterRow extends ConsumerWidget {
  final String vendorId;
  const _VegFilterRow({required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVeg = ref.watch(isPureVegProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Menu', style: AppTextStyles.headlineMedium),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(isPureVegProvider.notifier).toggle();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isVeg ? AppColors.vegGreen.withOpacity(0.1) : AppColors.grey100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isVeg ? AppColors.vegGreen.withOpacity(0.5) : AppColors.grey200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _miniVegIcon(isVeg),
                  const SizedBox(width: 6),
                  Text(
                    'Veg Only',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isVeg ? AppColors.vegGreen : AppColors.grey600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniVegIcon(bool isVeg) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(
          color: isVeg ? AppColors.vegGreen : AppColors.grey400,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isVeg ? AppColors.vegGreen : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Category Tab Delegate (Sticky Header) ─────────────────────
class _CategoryTabDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String vendorId;

  const _CategoryTabDelegate({
    required this.categories,
    required this.vendorId,
  });

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  bool shouldRebuild(_CategoryTabDelegate old) => old.categories != categories;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Consumer(builder: (context, ref, _) {
      final selected = ref.watch(selectedMenuCategoryProvider);
      return Container(
        height: 52,
        color: AppColors.background,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _CategoryChip(
                label: 'All',
                isSelected: selected == null,
                onTap: () => ref.read(selectedMenuCategoryProvider.notifier).state = null,
              ),
              ...categories.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _CategoryChip(
                    label: cat,
                    isSelected: selected == cat,
                    onTap: () => ref.read(selectedMenuCategoryProvider.notifier).state = cat,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricCoral : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.electricCoral : AppColors.grey200,
          ),
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

// ── Category Header ───────────────────────────────────────────
class _CategoryHeader extends StatelessWidget {
  final String category;
  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(category, style: AppTextStyles.headlineMedium),
    );
  }
}

// ── Menu Shimmer ──────────────────────────────────────────────
class _MenuShimmer extends SliverToBoxAdapter {
  _MenuShimmer()
      : super(
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.electricCoral,
                strokeWidth: 2,
              ),
            ),
          ),
        );
}

// ── Error View ────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Could not load menu', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Empty Menu ────────────────────────────────────────────────
class _EmptyMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'No items available right now',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Check back soon — the restaurant\nis preparing today's menu.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey500,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── FSSAI Footer ──────────────────────────────────────────────
class _FssaiFooter extends StatelessWidget {
  final VendorEntity vendor;
  const _FssaiFooter({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final fssai = vendor.fssaiLicense.trim();
    final fssaiText = fssai.isNotEmpty ? fssai : 'Not available';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 16, color: AppColors.vegGreen),
              const SizedBox(width: 6),
              Text(
                'FSSAI Licensed',
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.vegGreen),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('License No: $fssaiText', style: AppTextStyles.bodySmall),
          if (vendor.legalEntityName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Legal Entity: ${vendor.legalEntityName}', style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

// ── Floating Cart Bar ─────────────────────────────────────────
// FIX: Replaced .maybeWhen(loaded:...) with `is CartLoaded`.
class _FloatingCartBar extends ConsumerWidget {
  final VendorEntity vendor;
  const _FloatingCartBar({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);
    final countdown = ref.watch(cartCountdownProvider);

    if (cartState is! CartLoaded) return const SizedBox.shrink();
    final cart = cartState.cart;

    return SafeArea(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          CartBottomSheet.show(context);
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.electricCoral,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricCoral.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${cart.totalItemCount}',
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'View Cart · ${cart.totalDisplay}',
                  style: AppTextStyles.labelLarge,
                ),
              ),
              countdown.maybeWhen(
                data: (d) {
                  if (d == Duration.zero) return const SizedBox.shrink();
                  final mins = d.inMinutes;
                  final secs = d.inSeconds % 60;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: d.inSeconds < 90
                          ? Colors.red.withOpacity(0.3)
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$mins:${secs.toString().padLeft(2, '0')}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ✅ Vendor Info Screen (opens from ℹ️ icon)
// ============================================================
class VendorInfoScreen extends StatelessWidget {
  final VendorEntity vendor;
  const VendorInfoScreen({super.key, required this.vendor});
String _maskedGstin(String? gstin) {
  if (gstin == null || gstin.trim().isEmpty) {
    return 'Not available';
  }

  final clean = gstin.trim();

  // Very short GST numbers should not crash
  if (clean.length <= 5) {
    return clean;
  }

  // Keep first 2 chars and last 3 chars visible
  final start = clean.substring(0, 2);
  final end = clean.substring(clean.length - 3);

  // Mask middle part
  final maskedLength = clean.length - 5;

  return '$start${'X' * maskedLength}$end';
}

  DateTime? _tryGetJoinedDate() {
    // Safe: supports DateTime OR Timestamp-like via .toDate()
    try {
      final raw = (vendor as dynamic).createdAt;
      if (raw is DateTime) return raw;
      if (raw != null) {
        try {
          final d = (raw as dynamic).toDate();
          if (d is DateTime) return d;
        } catch (_) {}
      }
    } catch (_) {}

    try {
      final raw = (vendor as dynamic).joinedAt;
      if (raw is DateTime) return raw;
      if (raw != null) {
        try {
          final d = (raw as dynamic).toDate();
          if (d is DateTime) return d;
        } catch (_) {}
      }
    } catch (_) {}

    return null;
  }

  double? _tryGetLat() {
    try {
      final v = vendor as dynamic;
      final val = v.lat ?? v.latitude;
      if (val == null) return null;
      return (val as num).toDouble();
    } catch (_) {
      return null;
    }
  }

  double? _tryGetLng() {
    try {
      final v = vendor as dynamic;
      final val = v.lng ?? v.longitude;
      if (val == null) return null;
      return (val as num).toDouble();
    } catch (_) {
      return null;
    }
  }

  Future<void> _openDirections(BuildContext context) async {
    final lat = _tryGetLat();
    final lng = _tryGetLng();

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available for this vendor')),
      );
      return;
    }

    final uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final joined = _tryGetJoinedDate();
    final joinText = joined != null ? DateFormat('MMMM yyyy').format(joined) : 'Not available';

    final fssai = vendor.fssaiLicense.trim();
    final fssaiText = fssai.isNotEmpty ? fssai : 'Not available';
    final legalName = vendor.legalEntityName.trim().isNotEmpty
    ? vendor.legalEntityName
    : 'Not available';

final gstText = _maskedGstin(vendor.gstin);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Vendor Info', style: AppTextStyles.titleLarge),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.deepCharcoal,
            size: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vendor.businessName, style: AppTextStyles.headlineLarge),
            const SizedBox(height: 10),

            _InfoTile(
              icon: Icons.calendar_month_rounded,
              title: 'Joined Biteo',
              value: joinText,
            ),

            _InfoTile(
              icon: Icons.location_on_outlined,
              title: 'Address',
              value: vendor.fullAddress,
            ),

            _InfoTile(
              icon: Icons.verified_rounded,
              title: 'FSSAI License Number',
              value: fssaiText,
              valueColor: fssai.isNotEmpty ? AppColors.vegGreen : AppColors.grey600,
            ),
            _InfoTile(
  icon: Icons.business_rounded,
  title: 'Legal Entity Name',
  value: legalName,
),

_InfoTile(
  icon: Icons.receipt_long_rounded,
  title: 'GST Number',
  value: gstText,
),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openDirections(context),
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricCoral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

                        const SizedBox(height: 12),

SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () async {
      final phone = vendor.phoneNumber?.trim();

      if (phone == null || phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not available'),
          ),
        );
        return;
      }

      final uri = Uri.parse('tel:$phone');

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open phone app'),
          ),
        );
      }
    },
    icon: const Icon(Icons.call_rounded),
    label: const Text('Call Restaurant'),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.electricCoral,
      side: const BorderSide(
        color: AppColors.electricCoral,
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  ),
),

            const Spacer(),

            // FSSAI again at bottom (you wanted both places)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Text(
                'FSSAI: $fssaiText',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: fssai.isNotEmpty ? AppColors.deepCharcoal : AppColors.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.grey600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: valueColor ?? AppColors.deepCharcoal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}