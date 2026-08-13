// =============================================================
// lib/features/auth/domain/entities/biteo_user.dart
// The core User entity. This is a pure Dart class — zero Firebase
// imports. The data layer converts between Firestore documents
// and this entity. The UI and domain layers only ever see BiteoUser.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class BiteoUser {
  final String uid;
  final String phone;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final bool isProfileComplete;
  final bool isPureVeg;
  final bool hasSeenWelcomeModal;
  final DateTime createdAt;

  const BiteoUser({
    required this.uid,
    required this.phone,
    this.fullName,
    this.email,
    this.avatarUrl,
    required this.isProfileComplete,
    this.isPureVeg = false,
    this.hasSeenWelcomeModal = false,
    required this.createdAt,
  });

  /// Deserialises a Firestore document into a BiteoUser.
  /// Mirrors the exact schema from our approved data architecture.
  factory BiteoUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return BiteoUser(
      uid: uid,
      phone:              data['profile']?['phone']               as String?  ?? '',
      fullName:           data['profile']?['full_name']           as String?,
      email:              data['profile']?['email']               as String?,
      avatarUrl:          data['profile']?['avatar_url']          as String?,
      isProfileComplete:  data['profile']?['is_profile_complete'] as bool?    ?? false,
      isPureVeg:          data['commerce']?['is_pure_veg']        as bool?    ?? false,
      hasSeenWelcomeModal:data['hype_engine']?['has_seen_welcome_modal'] as bool? ?? false,
      createdAt: (data['metadata']?['created_at'] as Timestamp?)?.toDate()
          ?? DateTime.now(),
    );
  }

  /// Serialises a BiteoUser to the Firestore document format.
  /// Used only once — during profile creation in [AuthRepositoryImpl].
  Map<String, dynamic> toFirestore() {
    return {
      'profile': {
        'phone':               phone,
        'full_name':           fullName,
        'email':               email,
        'avatar_url':          avatarUrl,
        'is_profile_complete': isProfileComplete,
      },
      'commerce': {
        'is_pure_veg':         isPureVeg,
        'razorpay_contact':    phone,
      },
      'location': {
        'saved_addresses': [],
      },
      'hype_engine': {
        'has_seen_welcome_modal': hasSeenWelcomeModal,
        'referral_code':          null,
      },
      'metadata': {
        'created_at':      FieldValue.serverTimestamp(),
        'last_active_at':  FieldValue.serverTimestamp(),
        'fcm_token':       null,
        'app_version':     '1.0.0',
      },
    };
  }

  BiteoUser copyWith({
    String?   uid,
    String?   phone,
    String?   fullName,
    String?   email,
    String?   avatarUrl,
    bool?     isProfileComplete,
    bool?     isPureVeg,
    bool?     hasSeenWelcomeModal,
    DateTime? createdAt,
  }) {
    return BiteoUser(
      uid:                 uid                ?? this.uid,
      phone:               phone              ?? this.phone,
      fullName:            fullName           ?? this.fullName,
      email:               email              ?? this.email,
      avatarUrl:           avatarUrl          ?? this.avatarUrl,
      isProfileComplete:   isProfileComplete  ?? this.isProfileComplete,
      isPureVeg:           isPureVeg          ?? this.isPureVeg,
      hasSeenWelcomeModal: hasSeenWelcomeModal?? this.hasSeenWelcomeModal,
      createdAt:           createdAt          ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BiteoUser && other.uid == uid);

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'BiteoUser(uid: $uid, name: $fullName, phone: $phone)';
}