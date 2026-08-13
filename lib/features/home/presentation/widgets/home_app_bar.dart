// ============================================================
// lib/features/home/presentation/widgets/home_app_bar.dart
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/home_providers.dart';

class HomeSliverAppBar extends ConsumerWidget {
  final String? userName;
  const HomeSliverAppBar({super.key, this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationName = ref.watch(locationDisplayNameProvider);
    final authState = ref.watch(authNotifierProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    final String? avatarUrl = authState is AuthAuthenticated
        ? authState.user.avatarUrl
        : null;

    final String displayName = userName ??
        (authState is AuthAuthenticated
            ? (authState.user.fullName ?? 'Foodie')
            : 'Foodie');

    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 1,
      pinned: true,
      floating: true,
      snap: true,
      expandedHeight: 120,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,

      actions: [
        _BellButton(
          unreadCount: unreadCount,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(AppRoutes.notifications);
          },
        ),
        const SizedBox(width: 10),
        _ProfileAvatar(
          avatarUrl: avatarUrl,
          displayName: displayName,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(AppRoutes.profile);
          },
        ),
        const SizedBox(width: 16),
      ],

      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: IgnorePointer(
          ignoring: true,
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push(AppRoutes.mapLocation);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(displayName),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            locationName.when(
                              data: (name) => _LocationChip(text: name),
                              loading: () => const _LocationChip(
                                text: 'Getting location…',
                                isLoading: true,
                              ),
                              error: (_, __) => const _LocationChip(
                                text: 'Set location',
                                isError: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ FIXED POSITION
  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final time = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$time, ${name.split(' ').first} 👋';
  }
}

// ── Location Chip ─────────────────────────────────────────────
class _LocationChip extends StatelessWidget {
  final String text;
  final bool isLoading;
  final bool isError;

  const _LocationChip({
    required this.text,
    this.isLoading = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isError
              ? Icons.location_off_rounded
              : Icons.location_on_rounded,
          size: 14,
          color: isError ? AppColors.error : AppColors.electricCoral,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.titleMedium.copyWith(
              color: isError
                  ? AppColors.error
                  : AppColors.deepCharcoal,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isError && !isLoading)
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: AppColors.grey500,
          ),
      ],
    );
  }
}

// ── Bell Button ───────────────────────────────────────────────
class _BellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _BellButton({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: AppColors.deepCharcoal,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.electricCoral,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Profile Avatar ────────────────────────────────────────────
class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.avatarUrl,
    required this.displayName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.electricCoral.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      _InitialsAvatar(name: displayName),
                  errorWidget: (_, __, ___) =>
                      _InitialsAvatar(name: displayName),
                )
              : _InitialsAvatar(name: displayName),
        ),
      ),
    );
  }
}

// ── Initials Avatar ───────────────────────────────────────────
class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.electricCoral.withOpacity(0.15),
      child: Center(
        child: Text(
          _initials,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.electricCoral,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}