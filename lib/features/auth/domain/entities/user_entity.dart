import 'package:cloud_firestore/cloud_firestore.dart';

class UserEntity {
  final String uid;
  final String phone;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final bool isProfileComplete;
  final String foodPreference;
  final bool isPureVeg;
  final bool hasSeenWelcomeModal;
  final DateTime createdAt;

  // 🔥 NEW FIELD
  final String? lastAddressId;

  // =========================================================
  // ⭐ BITEO POINTS
  // =========================================================

  final int biteoPoints;
  final int pointsEarnedLifetime;
  final int pointsSpentLifetime;

  const UserEntity({
    required this.uid,
    required this.phone,
    this.fullName,
    this.email,
    this.avatarUrl,
    required this.isProfileComplete,
    this.foodPreference = 'Veg',
    this.isPureVeg = false,
    this.hasSeenWelcomeModal = false,
    required this.createdAt,

    // 🔥 EXISTING
    this.lastAddressId,

    // =====================================================
    // ⭐ BITEO POINTS
    // =====================================================

    this.biteoPoints = 0,
    this.pointsEarnedLifetime = 0,
    this.pointsSpentLifetime = 0,
  });

  // ✅ SAFE PARSING
  factory UserEntity.fromFirestore(
    Map<String, dynamic> data,
    String uid,
  ) {
    final profile =
        data['profile']
            as Map<String, dynamic>? ??
        {};

    final commerce =
        data['commerce']
            as Map<String, dynamic>? ??
        {};

    final hype =
        data['hype_engine']
            as Map<String, dynamic>? ??
        {};

    final metadata =
        data['metadata']
            as Map<String, dynamic>? ??
        {};

    return UserEntity(
      uid: uid,

      phone: profile['phone'] ?? '',

      fullName: profile['full_name'],

      email: profile['email'],

      avatarUrl: profile['avatar_url'],

      isProfileComplete:
          profile['is_profile_complete'] ??
              false,

      foodPreference:
          commerce['food_preference'] ??
              'Veg',

      isPureVeg:
          commerce['is_pure_veg'] ??
              false,

      hasSeenWelcomeModal:
          hype['has_seen_welcome_modal'] ??
              false,

      createdAt:
          (metadata['created_at']
                      as Timestamp?)
                  ?.toDate() ??
              DateTime.now(),

      // 🔥 EXISTING
      lastAddressId:
          data['last_address_id'],

      // =====================================================
      // ⭐ BITEO POINTS
      // =====================================================

      biteoPoints:
          data['biteoPoints'] ?? 0,

      pointsEarnedLifetime:
          data['pointsEarnedLifetime'] ??
              0,

      pointsSpentLifetime:
          data['pointsSpentLifetime'] ??
              0,
    );
  }

  // ✅ KEEP STRUCTURE
  Map<String, dynamic> toFirestore() {
    return {
      'profile': {
        'phone': phone,
        'full_name': fullName,
        'email': email,
        'avatar_url': avatarUrl,
        'is_profile_complete':
            isProfileComplete,
      },

      'commerce': {
        'food_preference':
            foodPreference,

        'is_pure_veg': isPureVeg,

        'razorpay_contact': phone,
      },

      'location': {
        'saved_addresses': [],
      },

      'hype_engine': {
        'has_seen_welcome_modal':
            hasSeenWelcomeModal,

        'referral_code': null,
      },

      'metadata': {
        'created_at':
            FieldValue.serverTimestamp(),

        'last_active_at':
            FieldValue.serverTimestamp(),

        'fcm_token': null,

        'app_version': '1.0.0',
      },

      // =====================================================
      // ⭐ BITEO POINTS
      // =====================================================

      'biteoPoints': biteoPoints,

      'pointsEarnedLifetime':
          pointsEarnedLifetime,

      'pointsSpentLifetime':
          pointsSpentLifetime,
    };
  }

  // 🔥 FIXED copyWith
  UserEntity copyWith({
    String? uid,
    String? phone,
    String? fullName,
    String? email,
    String? avatarUrl,
    bool? isProfileComplete,
    String? foodPreference,
    bool? isPureVeg,
    bool? hasSeenWelcomeModal,
    DateTime? createdAt,

    // 🔥 EXISTING
    String? lastAddressId,

    // =====================================================
    // ⭐ BITEO POINTS
    // =====================================================

    int? biteoPoints,
    int? pointsEarnedLifetime,
    int? pointsSpentLifetime,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,

      phone: phone ?? this.phone,

      fullName:
          fullName ?? this.fullName,

      email: email ?? this.email,

      avatarUrl:
          avatarUrl ?? this.avatarUrl,

      isProfileComplete:
          isProfileComplete ??
              this.isProfileComplete,

      foodPreference:
          foodPreference ??
              this.foodPreference,

      isPureVeg:
          isPureVeg ?? this.isPureVeg,

      hasSeenWelcomeModal:
          hasSeenWelcomeModal ??
              this.hasSeenWelcomeModal,

      createdAt:
          createdAt ?? this.createdAt,

      // 🔥 EXISTING
      lastAddressId:
          lastAddressId ??
              this.lastAddressId,

      // =====================================================
      // ⭐ BITEO POINTS
      // =====================================================

      biteoPoints:
          biteoPoints ??
              this.biteoPoints,

      pointsEarnedLifetime:
          pointsEarnedLifetime ??
              this.pointsEarnedLifetime,

      pointsSpentLifetime:
          pointsSpentLifetime ??
              this.pointsSpentLifetime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserEntity &&
          other.uid == uid);

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() =>
      'UserEntity(uid: $uid, name: $fullName, preference: $foodPreference, biteoPoints: $biteoPoints)';
}