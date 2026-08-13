// ============================================================
// lib/features/home/presentation/widgets/vendor_card.dart
// FINAL SAFE VERSION
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/vendor_entity.dart';

class VendorCard extends StatelessWidget {
  final VendorEntity vendor;
  final VoidCallback onTap;

  const VendorCard({
    super.key,
    required this.vendor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: vendor.isCurrentlyOpen
              ? AppColors.cardBackground
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: vendor.isCurrentlyOpen ? 1 : 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoverImage(vendor: vendor),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  13,
                  14,
                  15,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            vendor.businessName,
                            style:
                                AppTextStyles.titleLarge,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 8),

                        _FssaiBadge(),
                      ],
                    ),

                    const SizedBox(height: 7),

                    if (vendor.tags.isNotEmpty) ...[
                      _TagRow(tags: vendor.tags),
                      const SizedBox(height: 10),
                    ],

                    const Divider(height: 1),

                    const SizedBox(height: 10),

                    _CardFooter(vendor: vendor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
// COVER IMAGE
// ─────────────────────────────────────

class _CoverImage extends StatelessWidget {
  final VendorEntity vendor;

  const _CoverImage({
    required this.vendor,
  });

  @override
  Widget build(BuildContext context) {
    final coverImageUrl =
        (vendor.coverImageUrl ?? '').toString();

    final logoUrl =
        (vendor.brandLogoUrl ?? '').toString();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(20),
      ),
      child: Stack(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: coverImageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: coverImageUrl,
                    fit: BoxFit.cover,

                    placeholder: (_, __) {
                      return Container(
                        color: AppColors.grey200,
                        child: const Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.grey400,
                            size: 40,
                          ),
                        ),
                      );
                    },

                    errorWidget:
                        (_, __, ___) {
                      return _PlaceholderCover();
                    },
                  )
                : _PlaceholderCover(),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 70,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(
                      0.35,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─────────────────────────
          // LOGO
          // ─────────────────────────

          if (logoUrl.isNotEmpty)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: logoUrl,
                    fit: BoxFit.cover,

                    errorWidget:
                        (_, __, ___) {
                      return const Icon(
                        Icons.storefront_rounded,
                        color:
                            AppColors.grey400,
                        size: 22,
                      );
                    },
                  ),
                ),
              ),
            ),

          // ─────────────────────────
          // DISTANCE BADGE
          // ─────────────────────────

          if (vendor.distanceText.isNotEmpty)
            Positioned(
              top: 12,
              right: 12,
              child: _DistanceBadge(
                text: vendor.distanceText,
              ),
            ),

          // ─────────────────────────
          // CLOSED OVERLAY
          // ─────────────────────────

          if (!vendor.isCurrentlyOpen)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black
                      .withOpacity(0.62),
                ),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      'Currently Closed',
                      style: AppTextStyles
                          .bodySmall
                          .copyWith(
                        color: AppColors
                            .deepCharcoal,
                        fontWeight:
                            FontWeight.w700,
                      ),
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

// ─────────────────────────────────────
// PLACEHOLDER COVER
// ─────────────────────────────────────

class _PlaceholderCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: AppColors.electricCoral
          .withOpacity(0.08),
      child: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Text(
              '🍽️',
              style: TextStyle(
                fontSize: 46,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Photo coming soon',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
// DISTANCE BADGE
// ─────────────────────────────────────

class _DistanceBadge extends StatelessWidget {
  final String text;

  const _DistanceBadge({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.electricCoral,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricCoral
                .withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 11,
          ),

          const SizedBox(width: 3),

          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────
// FSSAI BADGE
// ─────────────────────────────────────

class _FssaiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color:
            AppColors.vegGreen.withOpacity(
          0.1,
        ),
        borderRadius:
            BorderRadius.circular(6),
        border: Border.all(
          color:
              AppColors.vegGreen.withOpacity(
            0.3,
          ),
          width: 1,
        ),
      ),
      child: Text(
        'FSSAI ✓',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.vegGreen,
          fontWeight: FontWeight.w700,
          fontSize: 9.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
// TAG ROW
// ─────────────────────────────────────

class _TagRow extends StatelessWidget {
  final List<String> tags;

  const _TagRow({
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final visibleTags =
        tags.take(3).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: visibleTags.map((tag) {
        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius:
                BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.grey200,
            ),
          ),
          child: Text(
            _capitalize(tag),
            style:
                AppTextStyles.caption.copyWith(
              color: AppColors.grey700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _capitalize(String s) {
    return s.isEmpty
        ? s
        : s[0].toUpperCase() +
            s.substring(1);
  }
}

// ─────────────────────────────────────
// CARD FOOTER
// ─────────────────────────────────────

class _CardFooter extends StatelessWidget {
  final VendorEntity vendor;

  const _CardFooter({
    required this.vendor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.star_rounded,
          size: 15,
          color: Color(0xFFF5A623),
        ),

        const SizedBox(width: 3),

        Text(
          vendor.ratingText,
          style: AppTextStyles.bodySmall,
        ),

        if (vendor.totalRatings > 0) ...[
          const SizedBox(width: 2),

          Text(
            '(${vendor.totalRatings})',
            style: AppTextStyles.caption,
          ),
        ],

        const SizedBox(width: 14),

        const Icon(
          Icons.access_time_rounded,
          size: 14,
          color: AppColors.grey500,
        ),

        const SizedBox(width: 3),

        Text(
          vendor.prepTimeText,
          style: AppTextStyles.bodySmall,
        ),

        const Spacer(),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: vendor.isCurrentlyOpen
                ? AppColors.vegGreen
                    .withOpacity(0.1)
                : AppColors.grey100,
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: vendor.isCurrentlyOpen
                      ? AppColors.vegGreen
                      : AppColors.grey400,
                ),
              ),

              const SizedBox(width: 5),

              Text(
                vendor.isCurrentlyOpen
                    ? 'Open'
                    : 'Closed',
                style: AppTextStyles.caption
                    .copyWith(
                  color:
                      vendor.isCurrentlyOpen
                          ? AppColors.vegGreen
                          : AppColors.grey500,
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}