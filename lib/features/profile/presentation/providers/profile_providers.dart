// ============================================================
// lib/features/profile/presentation/providers/profile_providers.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/auth/presentation/providers/auth_state.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

// ── Notification Repository ───────────────────────────────────
final notificationRepositoryProvider =
    Provider<NotificationRepositoryImpl>(
  (_) => NotificationRepositoryImpl(),
);

// ── Live Notifications Stream ─────────────────────────────────
final notificationsProvider =
    StreamProvider.autoDispose<List<NotificationEntity>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) return Stream.value([]);

  return ref
      .watch(notificationRepositoryProvider)
      .watchNotifications(authState.user.uid);
});

// ── Unread Count ──────────────────────────────────────────────
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (list) => list.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});

// ── Mark Notifications ───────────────────────────────────────
class MarkNotificationsReadNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> markOne(String notificationId) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    await ref
        .read(notificationRepositoryProvider)
        .markAsRead(authState.user.uid, notificationId);
  }

  Future<void> markAll() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    await ref
        .read(notificationRepositoryProvider)
        .markAllAsRead(authState.user.uid);
  }
}

final markNotificationsReadProvider =
    NotifierProvider<MarkNotificationsReadNotifier, void>(
  MarkNotificationsReadNotifier.new,
);

// ── Order Summary ─────────────────────────────────────────────
class OrderSummary {
  final String orderId;
  final String vendorName;
  final String status;
  final int totalPaise;
  final DateTime? createdAt;

  const OrderSummary({
    required this.orderId,
    required this.vendorName,
    required this.status,
    required this.totalPaise,
    this.createdAt,
  });

  String get totalDisplay =>
      '₹${(totalPaise / 100).toStringAsFixed(0)}';

  String get statusDisplay => switch (status) {
        'confirmed' => 'Confirmed',
        'preparing' => 'Preparing',
        'ready' => 'Ready for Pickup',
        'completed' => 'Completed',
        'failed' => 'Failed',
        _ => 'Processing',
      };

  bool get isActive =>
      status == 'confirmed' ||
      status == 'preparing' ||
      status == 'ready';
}

// ── Orders Stream ─────────────────────────────────────────────
final recentOrdersProvider =
    StreamProvider.autoDispose<List<OrderSummary>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) return Stream.value([]);

  final uid = authState.user.uid;

  return FirebaseFirestore.instance
      .collection('orders')
      .where('parties.user_id', isEqualTo: uid)
      .limit(3)
      .snapshots()
      .map((snap) {
    final summaries = snap.docs.map((doc) {
      try {
        final d = doc.data();
        final parties = d['parties'] as Map<String, dynamic>? ?? {};
        final pricing = d['pricing'] as Map<String, dynamic>? ?? {};
        final fulfillment =
            d['fulfillment'] as Map<String, dynamic>? ?? {};
        final metadata = d['metadata'] as Map<String, dynamic>? ?? {};

        DateTime? createdAt;
        if (metadata['created_at'] is Timestamp) {
          createdAt =
              (metadata['created_at'] as Timestamp).toDate();
        }

        return OrderSummary(
          orderId: doc.id,
          vendorName: parties['vendor_name'] ?? 'Restaurant',
          status: fulfillment['status'] ?? 'confirmed',
          totalPaise:
              (pricing['total_charged'] as num?)?.toInt() ?? 0,
          createdAt: createdAt,
        );
      } catch (e) {
        _log.w('[Profile] Order parse error: $e');
        return null;
      }
    }).whereType<OrderSummary>().toList();

    summaries.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return summaries;
  });
});

// ── Order Count ───────────────────────────────────────────────
final orderCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) return 0;

  try {
    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('parties.user_id', isEqualTo: authState.user.uid)
        .get();
    return snap.size;
  } catch (e) {
    _log.w('[Profile] Order count error: $e');
    return 0;
  }
});

// ── User Profile Model ────────────────────────────────────────
class UserProfile {
  final String uid;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? dob;

  const UserProfile({
    required this.uid,
    required this.name,
    this.email,
    this.photoUrl,
    this.dob,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    final profile = data['profile'] as Map<String, dynamic>? ?? {};

    return UserProfile(
      uid: uid,
      name: profile['full_name'] ?? '',
      email: profile['email'],
      photoUrl: profile['avatar_url'],
      dob: profile['dob'],
    );
  }
}

// ── Profile Stream ────────────────────────────────────────────
final userProfileProvider =
    StreamProvider.autoDispose<UserProfile?>((ref) {
  final authState = ref.watch(authNotifierProvider);

  if (authState is! AuthAuthenticated) {
    return Stream.value(null);
  }

  final uid = authState.user.uid;

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      return UserProfile(uid: uid, name: 'Foodie');
    }

    return UserProfile.fromMap(uid, doc.data()!);
  });
});

// ── Update Profile ────────────────────────────────────────────
// ── Update Profile ────────────────────────────────────────────
class UpdateProfileNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> updateProfile({
  required String name,
  String? email,
  String? photoUrl,
  String? dob,
}) async {
  final authState = ref.read(authNotifierProvider);

  if (authState is! AuthAuthenticated) return;

state = const AsyncData(null); // no loading flicker

  try {
    final uid = authState.user.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
      'profile': {
        'full_name': name,
        if (email != null) 'email': email,
        if (photoUrl != null) 'avatar_url': photoUrl,
        if (dob != null) 'dob': dob,
      }
    }, SetOptions(merge: true));

    // ✅ ONLY THIS — enough
    ref.invalidate(userProfileProvider);

    state = const AsyncData(null);
  } catch (e, st) {
    _log.e('[Profile] Update failed: $e');
    state = AsyncError(e, st);
  }
}
}

final updateProfileProvider =
    NotifierProvider<UpdateProfileNotifier, AsyncValue<void>>(
  UpdateProfileNotifier.new,
);