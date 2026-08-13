// ============================================================
// lib/features/home/presentation/widgets/shimmer_vendor_card.dart
// Skeleton loading card — shown while vendor stream loads.
// Exactly mirrors the geometry of VendorCard so the transition
// from shimmer → real card is seamless (no layout jump).
// ============================================================
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';

class ShimmerVendorCard extends StatelessWidget {
  const ShimmerVendorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      // The shimmer sweeps from grey-200 (base) to white (highlight).
      baseColor: AppColors.grey200,
      highlightColor: Colors.white,
      period: const Duration(milliseconds: 1200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image skeleton (matches 16:9 ratio of real card)
            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business name skeleton
                  _ShimmerBox(width: 200, height: 18),
                  const SizedBox(height: 8),
                  // Tags skeleton
                  Row(children: [
                    _ShimmerBox(width: 70, height: 24),
                    const SizedBox(width: 8),
                    _ShimmerBox(width: 55, height: 24),
                    const SizedBox(width: 8),
                    _ShimmerBox(width: 80, height: 24),
                  ]),
                  const SizedBox(height: 12),
                  // Footer row skeleton
                  Row(children: [
                    _ShimmerBox(width: 48, height: 14),
                    const SizedBox(width: 16),
                    _ShimmerBox(width: 60, height: 14),
                    const Spacer(),
                    _ShimmerBox(width: 80, height: 14),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer Placeholder Box ───────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Shimmer List ─────────────────────────────────────────────
// Pre-built list of shimmer cards to display during loading.
class ShimmerVendorList extends StatelessWidget {
  final int count;
  const ShimmerVendorList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => const ShimmerVendorCard(),
        childCount: count,
      ),
    );
  }
}