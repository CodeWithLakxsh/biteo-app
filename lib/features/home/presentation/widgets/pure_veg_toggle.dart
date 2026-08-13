// ============================================================
// lib/features/home/presentation/widgets/pure_veg_toggle.dart
// Prominent Pure Veg toggle — a core Indian food app pattern.
// The green leaf icon signals vegetarian culture immediately.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/home_providers.dart';

class PureVegToggle extends ConsumerWidget {
  const PureVegToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVeg = ref.watch(isPureVegProvider);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(isPureVegProvider.notifier).toggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isVeg
              ? AppColors.vegGreen.withOpacity(0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isVeg
                ? AppColors.vegGreen.withOpacity(0.5)
                : AppColors.grey200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Veg indicator icon (green square with dot — Indian standard)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isVeg ? AppColors.vegGreen : AppColors.grey400,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isVeg ? AppColors.vegGreen : Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isVeg ? AppColors.vegGreen : AppColors.grey600,
                fontSize: 12.5,
              ),
              child: const Text('Pure Veg'),
            ),
            const SizedBox(width: 8),
            // Custom toggle switch
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                color: isVeg ? AppColors.vegGreen : AppColors.grey300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment:
                    isVeg ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}