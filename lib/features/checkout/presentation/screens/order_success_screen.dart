// ============================================================
// lib/features/checkout/presentation/screens/order_success_screen.dart
// Shown after successful payment + order creation.
// The OTP is the primary element — it's what the user shows
// to the vendor to collect their order.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/checkout_providers.dart';
import '../providers/checkout_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_tracking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderSuccessScreen extends ConsumerStatefulWidget {
  final CheckoutSuccess successData;
  const OrderSuccessScreen({super.key, required this.successData});

  @override
  ConsumerState<OrderSuccessScreen> createState() =>
      _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    // Haptic celebration.
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.successData;
    final orderId = data.orderId.length > 8
        ? '#${data.orderId.substring(0, 8).toUpperCase()}'
        : '#${data.orderId}';

    return PopScope(
      canPop: false, // Prevent back navigation from success screen.
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── Success Animation ──────────────────────
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.vegGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.vegGreen.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                     child: const Center(
  child: Icon(
    Icons.check_circle_rounded,
    color: AppColors.vegGreen,
    size: 60,
  ),
),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Headline ───────────────────────────────
                  // ── Headline ───────────────────────────────
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('orders')
      .doc(data.orderId)
      .snapshots(),
  builder: (context, snapshot) {
    String status = 'pending';

    if (snapshot.hasData && snapshot.data!.data() != null) {
      final orderData =
          snapshot.data!.data() as Map<String, dynamic>;
      status = orderData['status'] ?? 'pending';
    }

    String text;
    Color color;

    switch (status) {
      case 'pending':
        text = 'Waiting for Vendor';
        color = Colors.orange;
        break;
      case 'accepted':
        text = 'Order Accepted';
        color = Colors.blue;
        break;
      case 'preparing':
        text = 'Preparing Your Order';
        color = Colors.deepOrange;
        break;
      case 'ready':
        text = 'Ready for Pickup';
        color = Colors.green;
        break;
      case 'completed':
        text = 'Order Completed';
        color = Colors.green;
        break;
      case 'rejected':
        text = 'Order Rejected';
        color = Colors.red;
        break;
      default:
        text = 'Processing';
        color = Colors.grey;
    }

    return Text(
      text,
      style: AppTextStyles.displayMedium.copyWith(color: color),
      textAlign: TextAlign.center,
    );
  },
),

                  const SizedBox(height: 8),
                  Text(
                    data.vendorName,
                    style: AppTextStyles.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$orderId  ·  ${data.totalDisplay}',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 36),

if (data.pickupMode == 'pickup') ...[
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.electricCoral.withOpacity(0.3),
        width: 2,
      ),
    ),
    child: Column(
      children: [
        Text(
          'Your Pickup OTP',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.electricCoral,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          data.otpCode ?? '',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Show this OTP to vendor',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.grey500,
          ),
        ),
      ],
    ),
  ),
] else ...[
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.grey200),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.delivery_dining_rounded,
          size: 40,
          color: AppColors.electricCoral,
        ),
        const SizedBox(height: 12),
        Text(
          "Delivery on the way 🚚",
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          "Arriving in ~${data.estimatedReadyMinutes} mins",
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.grey500,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            final url = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${data.vendorName}',
            );
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
          icon: const Icon(Icons.map),
          label: const Text("Open Map"),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Rider will be assigned soon")),
            );
          },
          icon: const Icon(Icons.call),
          label: const Text("Call Rider"),
        ),
      ],
    ),
  ),
],

const SizedBox(height: 20),

                  // ── Pickup Info Card ───────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.access_time_rounded,
                          iconColor: AppColors.warning,
                          label: 'Estimated Ready',
                          value: '~${data.estimatedReadyMinutes} minutes',
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.store_rounded,
                          iconColor: AppColors.electricCoral,
                          label: 'Pickup Method',
                         value: data.pickupMode == 'delivery'
    ? 'Home Delivery'
    : (data.pickupMode == 'curbside'
        ? 'Curbside Pickup'
        : 'In-Store Pickup'),
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.receipt_rounded,
                          iconColor: const Color(0xFF6C63FF),
                          label: 'Payment',
                          value: 'Paid · ₹${(data.totalPaise / 100).toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                 if (data.pickupMode == 'pickup') ...[

  // ── Instructions ───────────────────────────
  Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.grey100,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 Pickup Instructions',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 10),
        _StepItem(
          step: '1',
          text: 'Head to ${data.vendorName}',
        ),
        _StepItem(
          step: '2',
          text: 'Tell the staff you have a Biteo order',
        ),
        if (data.otpCode != null)
          _StepItem(
            step: '3',
            text: 'Share your 4-digit OTP: ${data.otpCode}',
          ),
        _StepItem(
          step: '4',
          text: 'Collect your bag and enjoy!',
        ),
      ],
    ),
  ),

  const SizedBox(height: 24),

  // ── GET DIRECTIONS ─────────────────────────
  ElevatedButton.icon(
    onPressed: () async {
      final lat = 28.329216;
      final lng = 76.840864;

      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    },
    icon: const Icon(Icons.directions),
    label: const Text("Get Directions"),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.electricCoral,
      minimumSize: const Size(double.infinity, 50),
    ),
  ),

],

const SizedBox(height: 16), // ✅ FIX GAP

// ── CTA Buttons ────────────────────────────
ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      // Reset checkout state and go home.
                      ref.read(checkoutNotifierProvider.notifier).reset();
                      context.go(AppRoutes.home);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricCoral,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                      shadowColor:
                          AppColors.electricCoral.withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Back to Home',
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                   onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OrderTrackingScreen(
        orderId: data.orderId,
      ),
    ),
  );
},
                    icon: const Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                    ),
                    label: const Text('View Order Details'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(
                        color: AppColors.electricCoral,
                      ),
                      foregroundColor: AppColors.electricCoral,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 1),
            Text(value, style: AppTextStyles.titleMedium),
          ],
        ),
      ],
    );
  }
}

// ── Step Item ─────────────────────────────────────────────────
class _StepItem extends StatelessWidget {
  final String step;
  final String text;

  const _StepItem({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.electricCoral.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.electricCoral,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}