// =============================================================
// lib/core/widgets/biteo_button.dart
// The primary CTA button. Handles loading state, haptic feedback,
// and disabled state automatically. Used on every screen.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class BiteoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? labelColor;
  final IconData? prefixIcon;
  final double height;

  const BiteoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.labelColor,
    this.prefixIcon,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: (isLoading || onPressed == null)
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.electricCoral,
          disabledBackgroundColor:
              (backgroundColor ?? AppColors.electricCoral).withOpacity(0.55),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loader'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prefixIcon != null) ...[
                      Icon(prefixIcon,
                          size: 20, color: labelColor ?? Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: labelColor ?? Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}