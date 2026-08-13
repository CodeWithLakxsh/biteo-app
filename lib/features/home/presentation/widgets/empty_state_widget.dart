import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../../core/theme/app_theme.dart';

enum EmptyStateType { noVendors, locationError, networkError, generic }

class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final Object? error;
  final VoidCallback? onRetry;

  const EmptyStateWidget({
    super.key,
    this.type = EmptyStateType.generic,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final config = _config;

    // ❌ NO Center here (IMPORTANT FIX)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(config.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 20),

          Text(
            config.title,
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          Text(
            config.subtitle,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.grey500, height: 1.6),
            textAlign: TextAlign.center,
          ),

          if (onRetry != null) ...[
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry!();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(config.buttonLabel),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 50),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _EmptyConfig get _config {
    if (error is LocationFailure) {
      final lf = error as LocationFailure;

      if (lf == LocationFailure.permissionPermanentlyDenied) {
        return _EmptyConfig(
          emoji: '📍',
          title: 'Location Access Needed',
          subtitle: lf.userMessage,
          buttonLabel: 'Open Settings',
        );
      }

      return _EmptyConfig(
        emoji: '📍',
        title: 'Location Unavailable',
        subtitle: lf.userMessage,
        buttonLabel: 'Try Again',
      );
    }

    return switch (type) {
      EmptyStateType.noVendors => _EmptyConfig(
          emoji: '🔍',
          title: 'No restaurants nearby',
          subtitle:
              "We're growing! No Biteo partners within 5km yet.\nCheck back soon.",
          buttonLabel: 'Refresh',
        ),

      EmptyStateType.networkError => _EmptyConfig(
          emoji: '📶',
          title: 'No Connection',
          subtitle: "Please check your internet.",
          buttonLabel: 'Retry',
        ),

      _ => _EmptyConfig(
          emoji: '😕',
          title: 'Something went wrong',
          subtitle: 'Tap retry.',
          buttonLabel: 'Retry',
        ),
    };
  }
}

class _EmptyConfig {
  final String emoji, title, subtitle, buttonLabel;

  const _EmptyConfig({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });
}