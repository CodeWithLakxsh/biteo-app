// =============================================================
// lib/features/auth/presentation/widgets/hype_welcome_modal.dart
// The "Hype Engine" welcome modal. Shown exactly once per user,
// immediately after they complete their profile. Communicates
// the self-pickup model and the delivery unlock threshold.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/biteo_button.dart';

class HypeWelcomeModal extends StatefulWidget {
  const HypeWelcomeModal({super.key});

  @override
  State<HypeWelcomeModal> createState() => _HypeWelcomeModalState();
}

class _HypeWelcomeModalState extends State<HypeWelcomeModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Emoji celebration ──────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.coralSurface,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ──────────────────────────────────────
              Text(
                'You\'re officially in!',
                style: AppTextStyles.headlineLarge.copyWith(
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Welcome to Biteo. A world of premium surplus food at your fingertips.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // ── Delivery unlock callout ─────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.coralSurface,
                      AppColors.coralSurface.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.electricCoral.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🚀', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery is coming soon.',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Delivery unlocks after Biteo\'s first 100 successful network orders. '
                            'Enjoy Self-Pickup discounts until then!',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.charcoalMid,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Pickup modes row ───────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _PickupChip(
                      icon: Icons.store_outlined,
                      label: 'In-Store\nPickup',
                      isActive: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickupChip(
                      icon: Icons.directions_car_outlined,
                      label: 'Curbside\nPickup',
                      isActive: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickupChip(
                      icon: Icons.delivery_dining_outlined,
                      label: 'Delivery\nLocked',
                      isActive: false,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── CTA ────────────────────────────────────────
              BiteoButton(
                label: 'Explore Deals  →',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _PickupChip({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successLight : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.vegGreen.withOpacity(0.4)
              : AppColors.dividerGrey,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.success : AppColors.mutedGrey,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.success : AppColors.mutedGrey,
              height: 1.4,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          if (!isActive) ...[
            const SizedBox(height: 4),
            Icon(Icons.lock_outline_rounded,
                size: 10, color: AppColors.mutedGrey),
          ]
        ],
      ),
    );
  }
}