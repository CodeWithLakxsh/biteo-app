// =============================================================
// lib/features/auth/data/datasources/auth_remote_datasource.dart
// FIXED VERSION (NO LOGIC REMOVED)
// =============================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDataSource {
  Future<String> sendOtp(String phoneNumber);
  Future<UserCredential> verifyOtpAndSignIn({
    required String verificationId,
    required String otp,
  });
  Future<bool> isUserProfileComplete(String uid);
  Future<void> createUserProfile({
    required String uid,
    required String phone,
    required String fullName,
    required String foodPreference,
    required String? email,
  });
  Future<void> markWelcomeModalSeen(String uid);
  Future<void> signOut();
  Stream<User?> get authStateChanges;
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserDocument(String uid);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  @override
  Future<String> sendOtp(String phoneNumber) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {}
      },

      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  @override
  Future<UserCredential> verifyOtpAndSignIn({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<bool> isUserProfileComplete(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return false;
    return doc.data()!['profile']?['is_profile_complete'] as bool? ?? false;
  }

  @override
  Future<void> createUserProfile({
    required String uid,
    required String phone,
    required String fullName,
    required String foodPreference,
    required String? email,
  }) async {
    await _firestore.collection('users').doc(uid).set({

      'isBlocked': false,
      
      'profile': {
        'phone': phone,
        'full_name': fullName,
        'email': email,
        'avatar_url': null,
        'is_profile_complete': true,
      },
      'commerce': {
        'food_preference': foodPreference,
        'is_pure_veg': foodPreference == 'Veg',
        'razorpay_contact': phone,
      },
      'location': {
        'saved_addresses': [],
      },
      'hype_engine': {
        'has_seen_welcome_modal': false,
        'referral_code': null,
      },
      'metadata': {
        'created_at': FieldValue.serverTimestamp(),
        'last_active_at': FieldValue.serverTimestamp(),
        'fcm_token': null,
        'app_version': '1.0.0',
      },
    });
  }

  @override
  Future<void> markWelcomeModalSeen(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'hype_engine.has_seen_welcome_modal': true,
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();

  // ✅🔥 FINAL FIX HERE (CRITICAL)
  @override
  Stream<User?> get authStateChanges => _auth.userChanges();

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserDocument(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }
}