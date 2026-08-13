// ============================================================
// lib/features/profile/domain/entities/notification_entity.dart
// Pure domain entity. No Firebase, no Flutter imports.
// ============================================================

enum NotificationType {
  orderConfirmed,
  orderPreparing,
  orderReady,
  orderCompleted,
  promo,
  system,
}

extension NotificationTypeDisplay on NotificationType {
  String get label => switch (this) {
        NotificationType.orderConfirmed => 'Order Confirmed',
        NotificationType.orderPreparing => 'Being Prepared',
        NotificationType.orderReady => 'Ready for Pickup!',
        NotificationType.orderCompleted => 'Order Completed',
        NotificationType.promo => 'Special Offer',
        NotificationType.system => 'Biteo Update',
      };

  String get emoji => switch (this) {
        NotificationType.orderConfirmed => '✅',
        NotificationType.orderPreparing => '👨‍🍳',
        NotificationType.orderReady => '🛍️',
        NotificationType.orderCompleted => '⭐',
        NotificationType.promo => '🎉',
        NotificationType.system => 'ℹ️',
      };

  bool get isOrderUpdate => this != NotificationType.promo &&
      this != NotificationType.system;
}

class NotificationEntity {
  final String id;
  final NotificationType type;
  final String title;
  final String body;

  /// Non-null for order-related notifications.
  final String? orderId;

  /// Non-null for promo notifications with a banner image.
  final String? imageUrl;

  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
  });

  // ── Display Helpers ───────────────────────────────────────

  /// Human-readable relative time: "2 min ago", "Yesterday", etc.
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final d = createdAt;
    return '${d.day}/${d.month}/${d.year}';
  }

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      imageUrl: imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}