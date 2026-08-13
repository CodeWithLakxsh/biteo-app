// ============================================================
// lib/features/profile/presentation/screens/profile_screen.dart
// Zomato-style profile screen.
// Sections: Header, Stats, Activity, Preferences, Support.
// ============================================================
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../address/presentation/providers/address_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = 'v${info.version}');
      }
    } catch (_) {
      if (mounted) setState(() => _appVersion = 'v1.0.0');
    }
  }

  Future<void> _onSignOut() async {
    final confirmed = await _showSignOutDialog();
    if (confirmed == true && mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }

  Future<bool?> _showSignOutDialog() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SignOutSheet(
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

final authState = ref.watch(authNotifierProvider);

if (authState is! AuthAuthenticated) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

    final user = authState.user;
    final profileAsync = ref.watch(userProfileProvider);
    final orderCount = ref.watch(orderCountProvider);
    final recentOrders = ref.watch(recentOrdersProvider);
    final savedAddresses = ref.watch(savedAddressesProvider);
    final isPureVeg = ref.watch(isPureVegProvider);

    final biteoPoints =
    ref.watch(biteoPointsProvider);

    final addressCount = savedAddresses.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. App Bar ─────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.electricCoral,
            pinned: true,
            expandedHeight: 220,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                ),
              ),
            ),
            title: const Text(
              'My Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            // 🔥 ADD THIS (THIS IS WHAT YOU ASKED)
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/edit-profile');
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.edit,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    ),
  ],
            
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF6B6B),
                      Color(0xFFFF4444),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        _LargeAvatar(
                        avatarUrl: profileAsync.maybeWhen(
  data: (p) => p?.photoUrl ?? user.avatarUrl,
  orElse: () => user.avatarUrl,
),
                          displayName: user.fullName ?? 'Foodie',
                        ),
                        const SizedBox(width: 18),
                        // Name + phone
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                        profileAsync.when(
  data: (profile) {
    final name =
        profile?.name ?? user.fullName ?? 'Foodie';

    return Text(
      name,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  },
  loading: () => const SizedBox(),
  error: (_, __) => const SizedBox(),
),

const SizedBox(height: 4),

Text(
  user.phone,
  style: TextStyle(
    color: Colors.white.withOpacity(0.85),
    fontSize: 14,
    fontWeight: FontWeight.w400,
  ),
),

if (user.email != null && user.email!.isNotEmpty) ...[
  const SizedBox(height: 2),
  profileAsync.when(
    data: (profile) {
      final email = profile?.email ?? user.email;

      if (email == null || email.isEmpty) {
        return const SizedBox();
      }

      return Text(
        email,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    },
    loading: () => const SizedBox(),
    error: (_, __) => const SizedBox(),
  ),
],
],
), // closes Column
), // closes Expanded
], // closes Row children
), // closes Row
), // closes Padding
), // closes SafeArea
), // closes Container
), // closes FlexibleSpaceBar
), // closes SliverAppBar
          // ── 2. Stats Row ────────────────────────────────────
          SliverToBoxAdapter(
            child: _StatsRow(
  orderCount: orderCount.maybeWhen(
    data: (n) => n,
    orElse: () => 0,
  ),
  addressCount: addressCount,
  biteoPoints: biteoPoints,
),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── 3. Recent Orders ────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Recent Orders',
              trailing: 'View all →',
              onTrailingTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Full order history in Milestone 6! 🚀'),
                    margin: EdgeInsets.all(16),
                  ),
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: recentOrders.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.electricCoral,
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (_, __) => _EmptyOrders(),
              data: (orders) => orders.isEmpty
                  ? _EmptyOrders()
                  : Column(
                      children: orders
                          .map((o) => _OrderSummaryCard(order: o))
                          .toList(),
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── 4. Activity Section ─────────────────────────────
          const SliverToBoxAdapter(
            child: _SectionHeader(title: 'Activity'),
          ),

          SliverToBoxAdapter(
            child: _MenuSection(
              tiles: [
                _MenuTile(
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFF6C63FF),
                  title: 'My Orders',
                  subtitle: '${orderCount.maybeWhen(data: (n) => n, orElse: () => 0)} total orders',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order history in Milestone 6! 🚀'),
                        margin: EdgeInsets.all(16),
                      ),
                    );
                  },
                ),
                _MenuTile(
  icon: Icons.local_offer_rounded,
  iconColor: const Color(0xFFFF9800),
  title: 'Offers & Coupons',
  subtitle: 'View active offers and promo codes',
  onTap: () {
    HapticFeedback.lightImpact();
    context.push('/offers');
  },
),
_MenuTile(
  icon: Icons.workspace_premium_rounded,
  iconColor: Colors.amber,
  title: 'Biteo Points',
  subtitle: '$biteoPoints points available',
  onTap: () {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: 54,
              ),

              const SizedBox(height: 16),

              Text(
                '$biteoPoints Points',
                style: AppTextStyles.headlineMedium,
              ),

              const SizedBox(height: 8),

              Text(
                '1 Biteo Point = ₹1 discount',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.vegGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.savings_rounded,
                      color: AppColors.vegGreen,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Use your Biteo Points instantly during checkout.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
),
                _MenuTile(
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.electricCoral,
                  title: 'Saved Addresses',
                  subtitle: '$addressCount address${addressCount == 1 ? '' : 'es'} saved',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/saved-addresses');
                  },
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── 5. Preferences Section ──────────────────────────
          const SliverToBoxAdapter(
            child: _SectionHeader(title: 'Preferences'),
          ),

          SliverToBoxAdapter(
            child: _MenuSection(
              tiles: [
                _MenuTile(
                  icon: Icons.eco_rounded,
                  iconColor: AppColors.vegGreen,
                  title: 'Pure Veg Mode',
                  subtitle: 'Show only vegetarian options',
                  trailing: _VegToggle(
                    value: isPureVeg,
                    onChanged: (_) {
                      HapticFeedback.selectionClick();
                      ref.read(isPureVegProvider.notifier).toggle();
                    },
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(isPureVegProvider.notifier).toggle();
                  },
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── 6. Support Section ──────────────────────────────
          const SliverToBoxAdapter(
            child: _SectionHeader(title: 'Help & Support'),
          ),

          SliverToBoxAdapter(
            child: _MenuSection(
              tiles: [
                _MenuTile(
  icon: Icons.storefront_rounded,
  iconColor: const Color(0xFFFF8A00),
  title: 'Join Biteo',
  subtitle: 'Partner with Biteo and grow your business',
  onTap: () =>
      _launchUrl('https://join.biteo.in'),
),
                _MenuTile(
  icon: Icons.support_agent_rounded,
  iconColor: const Color(0xFF6C63FF),
  title: 'Support',
  subtitle: 'Chat with Biteo Support',
  onTap: () {
    HapticFeedback.lightImpact();
    context.push('/support');
  },
),

                _MenuTile(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.grey600,
                  title: 'Terms of Service',
                  onTap: () =>
                      _launchUrl('https://policy.biteo.in/'),
                ),
                _MenuTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppColors.grey600,
                  title: 'Privacy Policy',
                  onTap: () =>
                      _launchUrl('https://policy.biteo.in/'),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── 7. Sign Out Button ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: _onSignOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),

          // ── 8. Version Footer ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Biteo $_appVersion  ·  Made with ❤️ in India',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── Large Avatar ──────────────────────────────────────────────
class _LargeAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;

  const _LargeAvatar({
    required this.avatarUrl,
    required this.displayName,
  });

  String get _initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _InitialsFill(
                  initials: _initials,
                ),
                errorWidget: (_, __, ___) => _InitialsFill(
                  initials: _initials,
                ),
              )
            : _InitialsFill(initials: _initials),
      ),
    );
  }
}

class _InitialsFill extends StatelessWidget {
  final String initials;
  const _InitialsFill({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.25),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int orderCount;
  final int addressCount;
  final int biteoPoints;

  const _StatsRow({
    required this.orderCount,
    required this.addressCount,
    required this.biteoPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            value: '$orderCount',
            label: 'Orders\nPlaced',
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF6C63FF),
          ),
          _VerticalDivider(),
          _StatItem(
            value: '$addressCount',
            label: 'Saved\nAddresses',
            icon: Icons.location_on_rounded,
            iconColor: AppColors.electricCoral,
          ),
          _VerticalDivider(),
          _StatItem(
  value: '$biteoPoints',
  label: 'Biteo\nPoints',
  icon: Icons.workspace_premium_rounded,
  iconColor: Colors.amber,
),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      color: AppColors.grey200,
    );
  }
}

// ── Section Header ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const _SectionHeader({
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.grey600,
            fontSize: 11,
            letterSpacing: 0.8,
          )),
          const Spacer(),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailing!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.electricCoral,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Menu Section ──────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  final List<_MenuTile> tiles;
  const _MenuSection({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: tiles
            .asMap()
            .entries
            .map((entry) => Column(
                  children: [
                    entry.value,
                    if (entry.key < tiles.length - 1)
                      const Divider(
                        height: 1,
                        indent: 56,
                        endIndent: 16,
                      ),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

// ── Menu Tile ─────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            // Trailing
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.grey400,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}

// ── Veg Toggle (inline switch) ────────────────────────────────
class _VegToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _VegToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.vegGreen,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ── Order Summary Card ────────────────────────────────────────
class _OrderSummaryCard extends StatelessWidget {
  final OrderSummary order;
  const _OrderSummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: order.isActive
              ? AppColors.electricCoral.withOpacity(0.3)
              : AppColors.grey200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: order.isActive
                  ? AppColors.electricCoral.withOpacity(0.1)
                  : AppColors.grey100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              order.isActive
                  ? Icons.delivery_dining_rounded
                  : Icons.check_circle_outline_rounded,
              color: order.isActive
                  ? AppColors.electricCoral
                  : AppColors.grey500,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.vendorName,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.isActive
                            ? AppColors.electricCoral
                                .withOpacity(0.1)
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.statusDisplay,
                        style: AppTextStyles.caption.copyWith(
                          color: order.isActive
                              ? AppColors.electricCoral
                              : AppColors.grey600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (order.createdAt != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(order.createdAt!),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            order.totalDisplay,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.electricCoral,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${d.day}/${d.month}';
  }
}

// ── Empty Orders ──────────────────────────────────────────────
class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Text('🛍️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text('No orders yet', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Your past orders will appear here.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sign Out Sheet ────────────────────────────────────────────
class _SignOutSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _SignOutSheet({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('👋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Sign out?', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'You will need to log in again with your phone number.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey500, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Yes, sign out',
                  style: AppTextStyles.labelLarge),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: AppColors.grey300),
              ),
              child: Text(
                'Cancel',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.deepCharcoal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}