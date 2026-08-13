// ============================================================
// lib/features/profile/data/repositories/notification_repository_impl.dart
// Reads/writes users/{uid}/notifications sub-collection.
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/notification_entity.dart';

class NotificationRepositoryImpl {
  final FirebaseFirestore _db;
  final Logger _log;

  NotificationRepositoryImpl({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance,
        _log = Logger(printer: PrettyPrinter(methodCount: 0));

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('users').doc(userId).collection('notifications');

  // ── Watch all notifications (real-time) ──────────────────
  Stream<List<NotificationEntity>> watchNotifications(String userId) {
    return _col(userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map(_fromDoc)
            .whereType<NotificationEntity>()
            .toList());
  }

  // ── Mark a single notification as read ───────────────────
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _col(userId)
          .doc(notificationId)
          .update({'is_read': true});
    } catch (e) {
      _log.w('[Notifications] markAsRead error: $e');
    }
  }

  // ── Batch mark ALL unread as read ─────────────────────────
  Future<void> markAllAsRead(String userId) async {
    try {
      final snap = await _col(userId)
          .where('is_read', isEqualTo: false)
          .get();
      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
      _log.i('[Notifications] Marked ${snap.docs.length} as read.');
    } catch (e) {
      _log.e('[Notifications] markAllAsRead error', error: e);
    }
  }

  // ── Private: Firestore → Entity ───────────────────────────
  NotificationEntity? _fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final d = doc.data();
      if (d == null) return null;

      final typeStr = d['type'] as String? ?? 'system';
      final type = _parseType(typeStr);

      final createdAt = d['created_at'] is Timestamp
          ? (d['created_at'] as Timestamp).toDate()
          : DateTime.now();

      return NotificationEntity(
        id: doc.id,
        type: type,
        title: d['title'] as String? ?? type.label,
        body: d['body'] as String? ?? '',
        orderId: d['order_id'] as String?,
        imageUrl: d['image_url'] as String?,
        isRead: d['is_read'] as bool? ?? false,
        createdAt: createdAt,
      );
    } catch (e) {
      _log.w('[Notifications] Parse error for doc ${doc.id}: $e');
      return null;
    }
  }

  NotificationType _parseType(String value) => switch (value) {
        'order_confirmed' => NotificationType.orderConfirmed,
        'order_preparing' => NotificationType.orderPreparing,
        'order_ready' => NotificationType.orderReady,
        'order_completed' => NotificationType.orderCompleted,
        'promo' => NotificationType.promo,
        _ => NotificationType.system,
      };
}