// ============================================================
// lib/features/vendor/presentation/widgets/menu_item_card.dart
//
// FINAL SAFE VERSION
// ✅ Safe image loading
// ✅ Null-safe image URLs
// ✅ Dead URL fallback
// ✅ No image crash
// ✅ Vendor closed handling
// ✅ Cart protection
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cart/presentation/providers/cart_state.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../domain/entities/menu_item_entity.dart';

class MenuItemCard extends ConsumerWidget {
  final MenuItemEntity item;
  final String vendorId;
  final String vendorName;
  final bool isVendorOpen;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.vendorId,
    required this.vendorName,
    required this.isVendorOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.read(cartNotifierProvider);

    final int qtyInCart = cartState is CartLoaded
        ? cartState.cart.quantityOf(item.id)
        : 0;

    final bool isCartFromDifferentVendor =
        cartState is CartLoaded &&
            cartState.cart.vendorId != vendorId;

    // =========================================================
    // ✅ SAFE IMAGE URL
    // =========================================================

    final imageUrl =
        (item.imageUrl ?? '')
            .toString()
            .trim();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===================================================
          // LEFT SIDE
          // ===================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Veg indicator + title
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _VegIndicator(
                      isVeg: item.isVeg,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        item.name,
                        style:
                            AppTextStyles.titleMedium,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Description
                if (item.description != null &&
                    item.description!
                        .trim()
                        .isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Text(
                    item.description!,
                    style: AppTextStyles.bodySmall
                        .copyWith(
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Pricing
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    // Discounted price
                    Text(
                      item.discountedPriceDisplay,
                      style: AppTextStyles
                          .titleMedium
                          .copyWith(
                        color:
                            AppColors.electricCoral,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(width: 7),

                    // Original price
                    Text(
                      item.originalPriceDisplay,
                      style: AppTextStyles.caption
                          .copyWith(
                        decoration:
                            TextDecoration
                                .lineThrough,
                        decorationColor:
                            AppColors.grey400,
                        color:
                            AppColors.grey400,
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Discount badge
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.vegGreen
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(
                          6,
                        ),
                      ),
                      child: Text(
                        item.discountBadge,
                        style: AppTextStyles
                            .caption
                            .copyWith(
                          color:
                              AppColors.vegGreen,
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),

                // Low stock warning
                if (item.availableQuantity <= 3 &&
                    item.isInStock) ...[
                  const SizedBox(height: 5),

                  Text(
                    'Only ${item.availableQuantity} left!',
                    style: AppTextStyles.caption
                        .copyWith(
                      color: AppColors.warning,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ===================================================
          // RIGHT SIDE
          // ===================================================

          Column(
            children: [
              // =================================================
              // SAFE IMAGE
              // =================================================

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(12),
                child: SizedBox(
                  width: 96,
                  height: 90,

                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,

                          placeholder: (
                            context,
                            url,
                          ) {
                            return Container(
                              color: Colors
                                  .grey
                                  .shade200,
                              child:
                                  const Center(
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },

                          errorWidget: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Container(
                              color: Colors
                                  .grey
                                  .shade300,
                              child:
                                  const Center(
                                child: Icon(
                                  Icons
                                      .fastfood_rounded,
                                  size: 34,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color:
                              Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons
                                  .fastfood_rounded,
                              size: 34,
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              // =================================================
              // CTA BUTTONS
              // =================================================

              if (!isVendorOpen)
                _RestaurantClosedBadge()

              else if (!item.isInStock)
                _SoldOutBadge()

              else if (qtyInCart == 0)
                _AddButton(
                  onTap:
                      isCartFromDifferentVendor
                          ? () =>
                              _showClearCartDialog(
                                context,
                                ref,
                              )
                          : () => _addItem(ref),
                )

              else
                _QuantityStepper(
                  quantity: qtyInCart,

                  onAdd: () => _addItem(ref),

                  onRemove: () {
                    ref
                        .read(
                          cartNotifierProvider
                              .notifier,
                        )
                        .removeItem(
                          menuItemId: item.id,
                          vendorId: vendorId,
                        );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // ADD ITEM
  // ===========================================================

  void _addItem(WidgetRef ref) {
    HapticFeedback.selectionClick();

    ref
        .read(cartNotifierProvider.notifier)
        .addItem(
          vendorId: vendorId,
          vendorName: vendorName,
          item: item,
        );
  }

  // ===========================================================
  // CLEAR CART DIALOG
  // ===========================================================

  void _showClearCartDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,

      builder: (_) {
        return _ClearCartSheet(
          onConfirm: () async {
            Navigator.pop(context);

            await ref
                .read(
                  cartNotifierProvider.notifier,
                )
                .clearCart();

            // Prevent rebuild race
            await Future.delayed(
              const Duration(milliseconds: 200),
            );

            if (context.mounted) {
              _addItem(ref);
            }
          },
        );
      },
    );
  }
}

// ============================================================
// VEG INDICATOR
// ============================================================

class _VegIndicator extends StatelessWidget {
  final bool isVeg;

  const _VegIndicator({
    required this.isVeg,
  });

  @override
  Widget build(BuildContext context) {
    final color = isVeg
        ? AppColors.vegGreen
        : AppColors.nonVegMaroon;

    return Container(
      width: 16,
      height: 16,

      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 1.5,
        ),

        borderRadius:
            BorderRadius.circular(3),
      ),

      child: Center(
        child: Container(
          width: 8,
          height: 8,

          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NO IMAGE PLACEHOLDER
// ============================================================

class _NoImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 90,

      color: AppColors.electricCoral
          .withOpacity(0.06),

      child: const Center(
        child: Text(
          '🍱',
          style: TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}

// ============================================================
// SOLD OUT BADGE
// ============================================================

class _SoldOutBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 32,

      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius:
            BorderRadius.circular(8),

        border: Border.all(
          color: AppColors.grey300,
        ),
      ),

      child: Center(
        child: Text(
          'Sold Out',

          style: AppTextStyles.caption
              .copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.grey500,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RESTAURANT CLOSED
// ============================================================

class _RestaurantClosedBadge
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 34,

      decoration: BoxDecoration(
        color: AppColors.grey100,

        borderRadius:
            BorderRadius.circular(10),

        border: Border.all(
          color: AppColors.grey300,
        ),
      ),

      child: Center(
        child: Text(
          'Closed',

          style: AppTextStyles.caption
              .copyWith(
            color: AppColors.grey500,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ADD BUTTON
// ============================================================

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 80,
        height: 34,

        decoration: BoxDecoration(
          color: AppColors.electricCoral,

          borderRadius:
              BorderRadius.circular(10),

          boxShadow: [
            BoxShadow(
              color: AppColors.electricCoral
                  .withOpacity(0.3),

              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Center(
          child: Text(
            'ADD',

            style: AppTextStyles.labelLarge
                .copyWith(
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// QUANTITY STEPPER
// ============================================================

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantityStepper({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 34,

      decoration: BoxDecoration(
        color: AppColors.electricCoral,
        borderRadius:
            BorderRadius.circular(10),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,

        children: [
          GestureDetector(
            onTap: onRemove,

            child: const Padding(
              padding: EdgeInsets.all(6),

              child: Icon(
                Icons.remove_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),

          Text(
            '$quantity',

            style: AppTextStyles.labelLarge
                .copyWith(
              fontSize: 14,
            ),
          ),

          GestureDetector(
            onTap: onAdd,

            child: const Padding(
              padding: EdgeInsets.all(6),

              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CLEAR CART SHEET
// ============================================================

class _ClearCartSheet extends StatelessWidget {
  final VoidCallback onConfirm;

  const _ClearCartSheet({
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        16,
        24,
        40,
      ),

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
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,

                decoration: BoxDecoration(
                  color: AppColors.grey300,

                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              '🛒',
              style: TextStyle(fontSize: 40),
            ),

            const SizedBox(height: 12),

            Text(
              'Start a new cart?',
              style:
                  AppTextStyles.headlineMedium,
            ),

            const SizedBox(height: 8),

            Text(
              'Your current cart has items from a different restaurant. Adding this item will clear your existing cart.',

              style: AppTextStyles.bodyMedium
                  .copyWith(
                color: AppColors.grey500,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: onConfirm,

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.electricCoral,

                minimumSize:
                    const Size(double.infinity, 52),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),

              child: Text(
                'Yes, start fresh',
                style:
                    AppTextStyles.labelLarge,
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },

              style: OutlinedButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, 52),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                side: const BorderSide(
                  color: AppColors.grey300,
                ),
              ),

              child: Text(
                'Keep existing cart',

                style: AppTextStyles.labelLarge
                    .copyWith(
                  color:
                      AppColors.deepCharcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}