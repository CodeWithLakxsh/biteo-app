// ============================================================
// lib/features/checkout/presentation/screens/checkout_screen.dart
// Order summary + payment initiation screen.
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cart/domain/entities/cart_entity.dart';
import '../../../cart/presentation/providers/cart_state.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../providers/checkout_providers.dart';
import '../providers/checkout_state.dart';
import '../../../address/presentation/providers/address_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() =>
      _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String selectedMode = 'pickup';

  final TextEditingController _noteController =
    TextEditingController();

bool noCutlery = false;

bool useBiteoPoints = true;

String? appliedCouponCode;

int couponDiscountPaise = 0;

Map<String, dynamic>? appliedCoupon;

@override
void dispose() {
  _noteController.dispose();
  super.dispose();
}

@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(checkoutNotifierProvider.notifier).reset();
  });

  ref.listenManual<CheckoutState>(
    checkoutNotifierProvider,
    (prev, next) {
      if (!mounted) return;

      if (next is CheckoutSuccess) {
        context.pushReplacement(
          AppRoutes.orderSuccess,
          extra: next,
        );
      }

      if (next is CheckoutFailure) {
        HapticFeedback.heavyImpact();

        _showError(
          next.message,
          next.isPaymentFailed,
        );
      }
    },
  );
}

@override
Widget build(BuildContext context) {
final cartState = ref.watch(cartNotifierProvider);
final checkoutState = ref.watch(checkoutNotifierProvider);
final selectedAddress = ref.watch(selectedAddressProvider);

if (cartState is! CartLoaded) {
  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}

final cart = cartState.cart;

final biteoPoints =
    ref.watch(biteoPointsProvider);

final maxDiscountPaise =
    biteoPoints * 100;

final usableDiscountPaise =
    useBiteoPoints
        ? (
            maxDiscountPaise > cart.totalPaise
                ? cart.totalPaise
                : maxDiscountPaise
          )
        : 0;

final gstPaise =
    (cart.subtotalPaise * 0.05).round();

/// Base total before discounts
final grossTotalPaise =
    cart.subtotalPaise +
    cart.platformFeePaise +
    gstPaise;

/// Apply Biteo points
final afterPointsPaise =
    grossTotalPaise -
    usableDiscountPaise;

/// Apply coupon
final finalPayablePaise =
    (afterPointsPaise - couponDiscountPaise)
        .clamp(0, 999999999);

/// Reward points earned
final earnedPoints =
    ((finalPayablePaise ~/ 100) * 0.05)
        .floor();
    final isLoading = checkoutState is CheckoutCreatingOrder ||
        checkoutState is CheckoutVerifying;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.deepCharcoal,
              ),
            ),
          ),
        ),
        title: Text('Checkout', style: AppTextStyles.headlineMedium),
      ),

      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _VendorHeader(vendorName: cart.vendorName),
              ),
              const SliverToBoxAdapter(
                child: _SectionLabel(text: 'Your Items'),
              ),
              SliverToBoxAdapter(
                child: _ItemsList(cart: cart),
              ),
              const SliverToBoxAdapter(
  child: _SectionLabel(
    text: 'Restaurant Requests',
  ),
),

SliverToBoxAdapter(
  child: _RestaurantRequestCard(
    controller: _noteController,
    noCutlery: noCutlery,
    onCutleryChanged: (value) {
      setState(() {
        noCutlery = value;
      });
    },
  ),
),
              const SliverToBoxAdapter(
                child: _SectionLabel(text: 'Pickup Method'),
              ),
              SliverToBoxAdapter(
                child: _PickupModeCard(
                  selectedMode: selectedMode,
                  onChanged: (mode) {
                    setState(() => selectedMode = mode);
                  },
                ),
              ),
              const SliverToBoxAdapter(
  child: _SectionLabel(
    text: 'Offers & Coupons',
  ),
),

SliverToBoxAdapter(
  child: _CouponCard(
    cartTotalPaise: cart.totalPaise,

    appliedCouponCode:
        appliedCouponCode,

    onCouponApplied: (
      couponCode,
      discountPaise,
      couponData,
    ) {

      setState(() {

        appliedCouponCode =
            couponCode;

        couponDiscountPaise =
            discountPaise;

        appliedCoupon =
            couponData;
      });
    },

    onCouponRemoved: () {

      setState(() {

        appliedCouponCode = null;

        couponDiscountPaise = 0;

        appliedCoupon = null;
      });
    },
  ),
),

SliverToBoxAdapter(
  child: _BiteoPointsCard(
    availablePoints: biteoPoints,
    usableDiscountPaise: usableDiscountPaise,
    earnedPoints: earnedPoints,

    usePoints: useBiteoPoints,

    onChanged: (value) {
      setState(() {
        useBiteoPoints = value;
      });
    },
  ),
),
              SliverToBoxAdapter(
  child: _CompactBillCard(
    cart: cart,

    biteoDiscountPaise:
        usableDiscountPaise,

    couponDiscountPaise:
        couponDiscountPaise,

    appliedCouponCode:
        appliedCouponCode,

    finalPayablePaise:
        finalPayablePaise,
  ),
),

              SliverToBoxAdapter(
                child: _SavingsBanner(cart: cart),
              ),
              const SliverToBoxAdapter(
                child: _SafetyNote(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),

          /// 🔥 FIXED BOTTOM BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: selectedMode == 'delivery' && selectedAddress == null
                ? _AddAddressBar(
                    onTap: () {
                     context.push(AppRoutes.locationSearch);
                    },
                  )
                : _PlaceOrderBar(
                    cart: cart,
                    isLoading: isLoading,
                    finalPayablePaise: finalPayablePaise,
                    onTap: () {
                    if (isLoading) return;
                      HapticFeedback.mediumImpact();

                     if (selectedMode == 'delivery' && selectedAddress == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Please add delivery address')),
  );

  Future.delayed(const Duration(milliseconds: 300), () {
    if (!mounted) return;
    context.push(AppRoutes.locationSearch);
  });

  return; // 🔥 VERY IMPORTANT
}

                      ref
                          .read(checkoutNotifierProvider.notifier)
                          .placeOrder(
  mode: selectedMode,

  restaurantNote:
      _noteController.text.trim(),

  noCutlery: noCutlery,

  useBiteoPoints:
      useBiteoPoints,
);
                    },
                  ),
          ),

          if (isLoading)
            _LoadingOverlay(state: checkoutState),
        ],
      ),
    );
  }

  void _showError(String message, bool isPaymentFailed) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isPaymentFailed
                    ? Icons.payment_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}

// ── Section Label ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.grey600,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Vendor Header ─────────────────────────────────────────────
class _VendorHeader extends StatelessWidget {
  final String vendorName;
  const _VendorHeader({required this.vendorName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.electricCoral.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.electricCoral.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.electricCoral.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.electricCoral,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendorName,
                  style: AppTextStyles.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'FSSAI certified',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Items List ────────────────────────────────────────────────
class _ItemsList extends ConsumerWidget {

  final CartEntity cart;

  const _ItemsList({
    required this.cart,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: AppColors.grey200,
        ),
      ),

      child: Column(
        children: cart.items
            .asMap()
            .entries
            .map((entry) {

          final i = entry.key;
          final item = entry.value;

          return Column(
            children: [

Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 13,
  ),

  child: Row(
    crossAxisAlignment:
        CrossAxisAlignment.start,

    children: [

      Container(
        width: 14,
        height: 14,

        margin:
            const EdgeInsets.only(
          top: 4,
        ),

        decoration: BoxDecoration(
          border: Border.all(
            color: item.isVeg
                ? AppColors.vegGreen
                : AppColors.nonVegMaroon,
            width: 1.5,
          ),

          borderRadius:
              BorderRadius.circular(2),
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
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(
                  top: 6,
                ),

                child: Text(
                  item.name,
                  style:
                      AppTextStyles.titleMedium,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,

              children: [

                Container(
                  width: 110,
                  height: 36,

                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                            10),

                    border: Border.all(
                      color:
                          AppColors.electricCoral,
                    ),
                  ),

                  child: Row(
                    children: [

                      Expanded(
                        child: InkWell(
                          onTap: () {

                            ref
                                .read(
                                  cartNotifierProvider
                                      .notifier,
                                )
                                .decreaseQuantity(
                                  item.menuItemId,
                                );
                          },

                          child: const Icon(
                            Icons.remove,
                            size: 18,
                          ),
                        ),
                      ),

                      Container(
                        width: 1,
                        color:
                            AppColors.grey200,
                      ),

                      Expanded(
                        child: Center(
                          child: Text(
                            '${item.quantity}',

                            style:
                                AppTextStyles
                                    .titleMedium,
                          ),
                        ),
                      ),

                      Container(
                        width: 1,
                        color:
                            AppColors.grey200,
                      ),

                      Expanded(
                        child: InkWell(
                          onTap: () {

                            ref
                                .read(
                                  cartNotifierProvider
                                      .notifier,
                                )
                                .increaseQuantity(
                                  item.menuItemId,
                                );
                          },

                          child: const Icon(
                            Icons.add,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  item.lineTotalDisplay,
                  style: AppTextStyles
                      .titleMedium
                      .copyWith(
                    color:
                        AppColors.electricCoral,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
),

              if (i < cart.items.length - 1)
                const Divider(
                  height: 1,
                  indent: 40,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Pickup Mode Card ──────────────────────────────────────────
class _PickupModeCard extends StatelessWidget {
  final String selectedMode;
  final Function(String) onChanged;

  const _PickupModeCard({
    required this.selectedMode,
    required this.onChanged,
  });

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
      children: [
  GestureDetector(
    onTap: () => onChanged('pickup'),
    child: _PickupOption(
      icon: Icons.store_rounded,
      iconColor: AppColors.electricCoral,
      title: 'Self-Pickup',
      subtitle: 'In-store or Curbside — your choice at the venue',
      isSelected: selectedMode == 'pickup',
      isLocked: false,
    ),
  ),

  const Divider(height: 1),

  GestureDetector(
    onTap: () => onChanged('delivery'),
    child: _PickupOption(
      icon: Icons.delivery_dining_rounded,
      iconColor: AppColors.electricCoral,
      title: 'Delivery',
      subtitle: 'Get it delivered to your location',
      isSelected: selectedMode == 'delivery',
      isLocked: false,
    ),
  ),
],
      ),
    );
  }
}

class _PickupOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isLocked;

  const _PickupOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isLocked
                            ? AppColors.grey400
                            : AppColors.deepCharcoal,
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_rounded,
                          size: 13, color: AppColors.grey400),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: isLocked
                        ? AppColors.grey400
                        : AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.electricCoral,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 13),
            )
          else
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.grey300, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bill Breakdown ────────────────────────────────────────────
class _CompactBillCard extends StatelessWidget {

  final CartEntity cart;

  final int biteoDiscountPaise;
  final int couponDiscountPaise;
  final int finalPayablePaise;

  final String? appliedCouponCode;

  const _CompactBillCard({
    required this.cart,
    required this.biteoDiscountPaise,
    required this.couponDiscountPaise,
    required this.appliedCouponCode,
    required this.finalPayablePaise,
  });

  @override
  Widget build(BuildContext context) {

    final gstPaise =
        (cart.subtotalPaise * 0.05).round();

    return GestureDetector(

      onTap: () {

        showModalBottomSheet(
          context: context,

          backgroundColor: Colors.transparent,

          isScrollControlled: true,

          builder: (_) {

            return Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                14,
                20,
                32,
              ),

              decoration: const BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [

                  Container(
                    width: 42,
                    height: 5,

                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [

                      Text(
                        'Bill Details',
                        style:
                            AppTextStyles.titleLarge,
                      ),

                      const Spacer(),

                      Text(
                        '₹${(finalPayablePaise / 100).toStringAsFixed(0)}',

                        style: AppTextStyles
                            .titleLarge
                            .copyWith(
                          color:
                              AppColors.electricCoral,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _BillRow(
                    label: 'Item Total',

                    value:
                        cart.subtotalDisplay,
                  ),

                  const SizedBox(height: 14),

                  _BillRow(
                    label: 'Platform Fee',

                    value:
                        cart.platformFeeDisplay,
                  ),

                  const SizedBox(height: 14),

                  _BillRow(
                    label: 'GST & Taxes',

                    sublabel: '(5%)',

                    value:
                        '₹${(gstPaise / 100).toStringAsFixed(0)}',
                  ),

                  if (biteoDiscountPaise > 0) ...[

                    const SizedBox(height: 14),

                    _BillRow(
                      label: 'Biteo Points',

                      value:
                          '-₹${(biteoDiscountPaise / 100).toStringAsFixed(0)}',

                      valueColor:
                          AppColors.vegGreen,
                    ),
                  ],

                  if (couponDiscountPaise > 0) ...[

                    const SizedBox(height: 14),

                    _BillRow(
                      label:
                          'Coupon ($appliedCouponCode)',

                      value:
                          '-₹${(couponDiscountPaise / 100).toStringAsFixed(0)}',

                      valueColor:
                          AppColors.vegGreen,
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 18,
                    ),

                    child: Divider(height: 1),
                  ),

                  _BillRow(
                    label: 'Grand Total',

                    value:
                        '₹${(finalPayablePaise / 100).toStringAsFixed(0)}',

                    isBold: true,

                    valueColor:
                        AppColors.electricCoral,
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color:
                          AppColors.grey100,

                      borderRadius:
                          BorderRadius.circular(16),
                    ),

                    child: Row(
                      children: [

                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color:
                              AppColors.grey600,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'This amount includes all taxes and platform charges.',

                            style:
                                AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },

      child: Container(
        margin: const EdgeInsets.fromLTRB(
  16,
  20,
  16,
  0,
),

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color: AppColors.grey200,
          ),
        ),

        child: Row(
          children: [

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    'Total Bill',

                    style:
                        AppTextStyles.titleMedium,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Incl. taxes and charges',

                    style:
                        AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            Text(
              '₹${(finalPayablePaise / 100).toStringAsFixed(0)}',

              style: AppTextStyles
                  .headlineSmall
                  .copyWith(
                color:
                    AppColors.electricCoral,
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.keyboard_arrow_up_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _BiteoPointsCard extends StatelessWidget {

  final int availablePoints;
  final int usableDiscountPaise;
  final int earnedPoints;

  final bool usePoints;
  final ValueChanged<bool> onChanged;

  const _BiteoPointsCard({
    required this.availablePoints,
    required this.usableDiscountPaise,
    required this.earnedPoints,
    required this.usePoints,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: AppColors.grey200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Column(
  children: [

    Row(
      children: [

        const Icon(
          Icons.workspace_premium_rounded,
          color: Colors.amber,
        ),

        const SizedBox(width: 8),

        Text(
          'Biteo Points',
          style:
              AppTextStyles.titleMedium,
        ),
      ],
    ),

    const SizedBox(height: 14),

    Row(
      children: [

        Expanded(
          child: Text(
            'Use Biteo Points',
            style: AppTextStyles.bodyMedium,
          ),
        ),

        Switch(
          value: usePoints,
          onChanged: onChanged,
          activeColor: AppColors.electricCoral,
        ),
      ],
    ),
  ],
),

const SizedBox(height: 14),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [

              Text(
                'Available Balance',
                style:
                    AppTextStyles.bodyMedium,
              ),

              Text(
                '$availablePoints Points',
                style: AppTextStyles
                    .titleMedium
                    .copyWith(
                  color: AppColors.vegGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [

              Text(
                'Discount Applied',
                style:
                    AppTextStyles.bodyMedium,
              ),

              Text(
                '-₹${(usableDiscountPaise / 100).toStringAsFixed(0)}',
                style: AppTextStyles
                    .titleMedium
                    .copyWith(
                  color: AppColors.vegGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [

              Text(
                'You Will Earn',
                style:
                    AppTextStyles.bodyMedium,
              ),

              Text(
                '+$earnedPoints Points',
                style: AppTextStyles
                    .titleMedium
                    .copyWith(
                  color: AppColors.electricCoral,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            '1 Biteo Point = ₹1 discount',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}


class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final String? sublabel;
  final bool isBold;
  final Color? valueColor;

  const _BillRow({
    required this.label,
    required this.value,
    this.sublabel,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: isBold
              ? AppTextStyles.titleMedium
              : AppTextStyles.bodyMedium,
        ),
        if (sublabel != null) ...[
          const SizedBox(width: 4),
          Text(
            sublabel!,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.grey400),
          ),
        ],
        const Spacer(),
        Text(
          value,
          style: (isBold
              ? AppTextStyles.titleMedium
              : AppTextStyles.bodyMedium)
              .copyWith(
            color: valueColor ?? AppColors.deepCharcoal,
            fontSize: isBold ? 16 : null,
          ),
        ),
      ],
    );
  }
}

// ── Savings Banner ────────────────────────────────────────────
class _SavingsBanner extends StatelessWidget {
  final CartEntity cart;
  const _SavingsBanner({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.vegGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.vegGreen.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'You\'re saving money ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.vegGreen,
                    ),
                  ),
                  TextSpan(
                    text: 'on premium food.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.vegGreen,
                      fontWeight: FontWeight.w600,
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
}

// ── Safety Note ───────────────────────────────────────────────
class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded,
              size: 14, color: AppColors.grey400),
          const SizedBox(width: 6),
          Text(
            'Secured by Razorpay · 256-bit SSL encryption',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

// ── Place Order Bar ───────────────────────────────────────────
class _PlaceOrderBar extends StatelessWidget {
  final CartEntity cart;
  final bool isLoading;
  final int finalPayablePaise;
  final VoidCallback onTap;

  const _PlaceOrderBar({
    required this.cart,
    required this.isLoading,
    required this.finalPayablePaise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.electricCoral,
          disabledBackgroundColor:
              AppColors.electricCoral.withOpacity(0.6),
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: isLoading ? 0 : 4,
          shadowColor: AppColors.electricCoral.withOpacity(0.4),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing…',
                    style: AppTextStyles.labelLarge,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cart.totalItemCount} item${cart.totalItemCount > 1 ? 's' : ''}',
                      style: AppTextStyles.labelLarge
                          .copyWith(fontSize: 12),
                    ),
                  ),
                  Text(
                    'Pay & Place Order',
                    style: AppTextStyles.labelLarge,
                  ),
                  Text(
  '₹${(finalPayablePaise / 100).toStringAsFixed(0)}',
                    style: AppTextStyles.labelLarge
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }
}

// 🔥 ADD YOUR CLASS HERE
class _AddAddressBar extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAddressBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepCharcoal,
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Add Address to Continue',
          style: AppTextStyles.labelLarge.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Restaurant Request Card ──────────────────────────────────
class _RestaurantRequestCard extends StatelessWidget {
  final TextEditingController controller;
  final bool noCutlery;
  final ValueChanged<bool> onCutleryChanged;

  const _RestaurantRequestCard({
    required this.controller,
    required this.noCutlery,
    required this.onCutleryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final quickNotes = [
      'Less spicy',
      'Extra spicy',
      'Extra gravy',
      'No onion',
      'Less oil',
      'Extra crispy',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Text(
            'Special instructions',
            style: AppTextStyles.titleMedium,
          ),

          const SizedBox(height: 6),

          Text(
            'Add preferences for the restaurant',
            style: AppTextStyles.caption,
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickNotes.map((note) {
              return GestureDetector(
                onTap: () {
                  if (controller.text.isEmpty) {
                    controller.text = note;
                  } else {
                    controller.text =
                        '${controller.text}, $note';
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius:
                        BorderRadius.circular(30),
                  ),
                  child: Text(
                    note,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 120,
            decoration: InputDecoration(
              hintText:
                  'Example: Less spicy, no capsicum...',
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.electricCoral,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          GestureDetector(
            onTap: () {
              onCutleryChanged(!noCutlery);
            },
            child: Row(
              children: [

                Checkbox(
                  value: noCutlery,
                  onChanged: (v) {
                    onCutleryChanged(v ?? false);
                  },
                  activeColor:
                      AppColors.electricCoral,
                ),

                const SizedBox(width: 4),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        'I don’t need cutlery',
                        style:
                            AppTextStyles.bodyMedium,
                      ),

                      const SizedBox(height: 2),

                      Text(
                        'Help reduce plastic waste ♻️',
                        style: AppTextStyles.caption,
                      ),
                    ],
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

// ── Coupon Card ─────────────────────────────────────────────

class _CouponCard extends StatelessWidget {

  final int cartTotalPaise;

  final String? appliedCouponCode;

  final Function(
    String couponCode,
    int discountPaise,
    Map<String, dynamic> couponData,
  ) onCouponApplied;

  final VoidCallback onCouponRemoved;

  const _CouponCard({
    required this.cartTotalPaise,
    required this.appliedCouponCode,
    required this.onCouponApplied,
    required this.onCouponRemoved,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: () async {

        final result =
    await context.push(
  AppRoutes.couponSelection,

  extra: {
    'cartTotalPaise':
        cartTotalPaise,
  },
);

        if (result != null &&
            result is Map<String, dynamic>) {

          onCouponApplied(
            result['couponCode'],
            result['discountPaise'],
            result['couponData'],
          );
        }
      },

      child: Container(
        margin:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color: AppColors.grey200,
          ),
        ),

        child: Row(
          children: [

            const Icon(
              Icons.local_offer_rounded,
              color:
                  AppColors.electricCoral,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    appliedCouponCode != null
                        ? 'Coupon Applied'
                        : 'Apply Coupon',
                    style:
                        AppTextStyles.titleMedium,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    appliedCouponCode ??
                        'Tap to view available offers',
                    style:
                        AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            if (appliedCouponCode != null)

              GestureDetector(
                onTap:
                    onCouponRemoved,

                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.red,
                ),
              )

            else

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.grey500,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Loading Overlay ───────────────────────────────────────────
class _LoadingOverlay extends StatelessWidget {
  final CheckoutState state;
  const _LoadingOverlay({required this.state});

String get _message {
  if (state is CheckoutCreatingOrder) {
    return 'Preparing your order…';
  } else if (state is CheckoutVerifying) {
    return 'Confirming payment…';
  } else {
    return 'Please wait…';
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.electricCoral,
                strokeWidth: 3,
              ),
              const SizedBox(height: 18),
              Text(
                _message,
                style: AppTextStyles.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Do not press back or close the app.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}