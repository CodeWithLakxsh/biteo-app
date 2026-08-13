// ============================================================
// lib/features/profile/presentation/screens/notifications_screen.dart
// Real-time notification feed.
// Marks individual notifications read on tap.
// "Mark all read" in AppBar actions.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/profile_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Notifications',
                style: AppTextStyles.headlineMedium),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.electricCoral,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref
                    .read(markNotificationsReadProvider.notifier)
                    .markAll();
              },
              child: Text(
                'Mark all read',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.electricCoral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.electricCoral,
            strokeWidth: 2,
          ),
        ),
        error: (_, __) => _ErrorState(),
        data: (notifications) {
          if (notifications.isEmpty) return _EmptyState();

          // Group by today / yesterday / older.
          final today = <NotificationEntity>[];
          final yesterday = <NotificationEntity>[];
          final older = <NotificationEntity>[];
          final now = DateTime.now();

          for (final n in notifications) {
            final diff = now.difference(n.createdAt);
            if (diff.inDays == 0) {
              today.add(n);
            } else if (diff.inDays == 1) {
              yesterday.add(n);
            } else {
              older.add(n);
            }
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (today.isNotEmpty) ...[
                _DateHeader(label: 'Today'),
                ...today.map((n) => _NotificationCard(
                      notification: n,
                      onTap: () => ref
                          .read(markNotificationsReadProvider
                              .notifier)
                          .markOne(n.id),
                    )),
              ],
              if (yesterday.isNotEmpty) ...[
                _DateHeader(label: 'Yesterday'),
                ...yesterday.map((n) => _NotificationCard(
                      notification: n,
                      onTap: () => ref
                          .read(markNotificationsReadProvider
                              .notifier)
                          .markOne(n.id),
                    )),
              ],
              if (older.isNotEmpty) ...[
                _DateHeader(label: 'Earlier'),
                ...older.map((n) => _NotificationCard(
                      notification: n,
                      onTap: () => ref
                          .read(markNotificationsReadProvider
                              .notifier)
                          .markOne(n.id),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Date Group Header ─────────────────────────────────────────
class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        label,
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.grey600,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Notification Card ─────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  Color get _bgColor {
    if (notification.isRead) return Colors.white;
    return AppColors.electricCoral.withOpacity(0.04);
  }

  Color get _iconBg {
    return switch (notification.type) {
      NotificationType.orderReady =>
        AppColors.vegGreen.withOpacity(0.1),
      NotificationType.orderCompleted =>
        AppColors.vegGreen.withOpacity(0.1),
      NotificationType.promo =>
        AppColors.electricCoral.withOpacity(0.1),
      _ => AppColors.grey100,
    };
  }

  Color get _iconColor {
    return switch (notification.type) {
      NotificationType.orderReady => AppColors.vegGreen,
      NotificationType.orderCompleted => AppColors.vegGreen,
      NotificationType.promo => AppColors.electricCoral,
      _ => AppColors.grey600,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? AppColors.grey200
                : AppColors.electricCoral.withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  notification.type.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Unread dot
                      if (!notification.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.electricCoral,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: notification.isRead
                          ? AppColors.grey500
                          : AppColors.deepCharcoal,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.timeAgo,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(
              'All quiet here!',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Order updates, deals, and app news\nwill show up here.",
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey500, height: 1.65),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Could not load notifications',
            style: AppTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}