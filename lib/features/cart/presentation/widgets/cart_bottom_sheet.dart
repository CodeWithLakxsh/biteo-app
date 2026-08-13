// ============================================================
// lib/features/cart/presentation/widgets/cart_bottom_sheet.dart
// Full cart review sheet + countdown timer.
// FIX: Applied Claude's `is CartLoaded` state fix while keeping ALL your UI & Logics.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/cart_entity.dart';
import '../providers/cart_state.dart'; // Added Claude's import for CartLoaded
import '../providers/cart_providers.dart';
import 'package:go_router/go_router.dart';

class CartBottomSheet extends ConsumerWidget {
  const CartBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CartBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);

    // ── FIX: Claude's State Check (Replaced .maybeWhen) ──
    if (cartState is CartLoaded) {
      return _CartContent(cart: cartState.cart);
    }
    return const SizedBox.shrink();
  }
}

class _CartContent extends ConsumerWidget {
  final CartEntity cart;
  const _CartContent({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdown = ref.watch(cartCountdownProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            _Handle(),

            // Header: title + countdown
            _SheetHeader(countdown: countdown),

            const Divider(height: 1),

            // Scrollable items
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: cart.items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) => _CartItemRow(
                  item: cart.items[i],
                  // ── YOUR MVP FIX IS SAFE HERE ──
                  onAdd: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Redirecting to menu to add more items...'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onRemove: () => ref
                      .read(cartNotifierProvider.notifier)
                      .removeItem(
                        menuItemId: cart.items[i].menuItemId,
                        vendorId: cart.vendorId,
                      ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Bill summary
            _BillSummary(cart: cart),

            // Pickup mode note
            _PickupNote(),

            // CTA
            _CheckoutButton(cart: cart),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Handle ────────────────────────────────────────────────────
class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppColors.grey300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ── Sheet Header ──────────────────────────────────────────────
class _SheetHeader extends StatelessWidget {
  final AsyncValue<Duration> countdown;
  const _SheetHeader({required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Text('Your Cart', style: AppTextStyles.headlineMedium),
          const Spacer(),
          countdown.when(
            data: (remaining) {
              if (remaining == Duration.zero) return const SizedBox.shrink();
              final mins = remaining.inMinutes;
              final secs = remaining.inSeconds % 60;
              final isWarning = remaining.inSeconds < 90;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isWarning
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isWarning
                        ? AppColors.error.withOpacity(0.4)
                        : AppColors.warning.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: isWarning
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$mins:${secs.toString().padLeft(2, '0')}',
                      style: AppTextStyles.caption.copyWith(
                        color: isWarning
                            ? AppColors.error
                            : AppColors.warning,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Cart Item Row ─────────────────────────────────────────────
// ── Cart Item Row ─────────────────────────────────────────────
class _CartItemRow extends StatelessWidget {
  final CartItemEntity item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartItemRow({
    required this.item,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              border: Border.all(
                color: item.isVeg
                    ? AppColors.vegGreen
                    : AppColors.nonVegMaroon,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: item.isVeg
                      ? AppColors.vegGreen
                      : AppColors.nonVegMaroon,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.titleMedium),
                Text(item.unitPriceDisplay,
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onRemove();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: const Icon(Icons.remove_rounded, size: 14),
                ),
              ),
              const SizedBox(width: 12),
              Text('${item.quantity}',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onAdd();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.electricCoral,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              item.lineTotalDisplay,
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.electricCoral),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bill Summary ──────────────────────────────────────────────
class _BillSummary extends StatelessWidget {
  final CartEntity cart;
  const _BillSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        children: [
          _BillRow(label: 'Item total', value: cart.subtotalDisplay),
          const SizedBox(height: 6),
          _BillRow(
            label: 'Platform fee',
            value: cart.platformFeeDisplay,
            sublabel: '(5%)',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _BillRow(
            label: 'To Pay',
            value: cart.totalDisplay,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label, value;
  final String? sublabel;
  final bool isBold;

  const _BillRow({
    required this.label,
    required this.value,
    this.sublabel,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: isBold ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium,
        ),
        if (sublabel != null) ...[
          const SizedBox(width: 4),
          Text(sublabel!,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.grey400)),
        ],
        const Spacer(),
        Text(
          value,
          style: isBold
              ? AppTextStyles.titleMedium.copyWith(
                  color: AppColors.electricCoral,
                  fontSize: 16,
                )
              : AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

// ── Pickup Note ───────────────────────────────────────────────
class _PickupNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.store_rounded,
                size: 18, color: AppColors.deepCharcoal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Self-Pickup only  ·  Delivery unlocks after 100 orders',
                style: AppTextStyles.bodySmall.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Checkout Button (FINAL FIX) ───────────────────────────────
class _CheckoutButton extends StatelessWidget {
  final CartEntity cart;
  const _CheckoutButton({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);

          // 🔥 FINAL NAVIGATION
          context.push('/checkout');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricCoral,
          minimumSize: const Size(double.infinity, 56),
        ),
        child: Text('Proceed to Checkout • ${cart.totalDisplay}'),
      ),
    );
  }
}