import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'auth_state.dart';
import 'auth_providers.dart';

class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<User?>? _authSub;
  bool _initialized = false;

  @override
  AuthState build() {
    // ✅ CLEANUP FIX (IMPORTANT)
    ref.onDispose(() {
      _authSub?.cancel();
    });

    _initAuth();
    return const AuthInitial();
  }

  void _initAuth() {
    if (_initialized) return;
    _initialized = true;

    _authSub?.cancel();

    _authSub =
        FirebaseAuth.instance.userChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        final result = await ref
            .read(authRepositoryProvider)
            .getCurrentUser(firebaseUser.uid);

        result.fold(
          (_) {
            // ✅ FALLBACK USER (VERY IMPORTANT)
            state = AuthAuthenticated(
              user: UserEntity(
                uid: firebaseUser.uid,
                phone: firebaseUser.phoneNumber ?? '',
                fullName: '',
                foodPreference: '',
                email: firebaseUser.email,
                isProfileComplete: false,
                createdAt: DateTime.now(),
              ),
            );
          },
          (userModel) {
            state = AuthAuthenticated(user: userModel);
          },
        );
      } else {
        state = const AuthUnauthenticated();
      }
    });
  }

  // ✅🔥 FINAL FIXED refreshUser (SAFE + NO DATA WIPE)
  Future<void> refreshUser() async {
    final current = state;

    if (current is! AuthAuthenticated) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(current.user.uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data();

      if (data == null) return;

      // ✅ SAFE PARSE (VERY IMPORTANT)
      final profile =
          (data['profile'] as Map<String, dynamic>?) ?? {};

final updatedUser = current.user.copyWith(
  fullName:
      profile['full_name'] as String? ?? current.user.fullName,
  email: profile['email'] as String? ?? current.user.email,
  avatarUrl:
      profile['avatar_url'] as String? ?? current.user.avatarUrl,
);

      // ✅ PREVENT UNNECESSARY REBUILD LOOP
      if (updatedUser != current.user) {
        state = AuthAuthenticated(user: updatedUser);
      }
    } catch (e) {
      print("refreshUser error: $e");
    }
  }

Future<void> sendOtp(String rawPhone) async {
  try {

    state = const AuthLoading();

    final e164Phone =
        rawPhone.startsWith('+')
            ? rawPhone
            : '+91$rawPhone';

    // ✅ CHECK BLOCKED USER
   final query =
    await FirebaseFirestore.instance
        .collection('users')
        .where(
  'commerce.razorpay_contact',
  isEqualTo: e164Phone,
)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {

      final userData =
          query.docs.first.data();

      final isBlocked =
          userData['isBlocked'] ?? false;

      if (isBlocked == true) {

        state = const AuthError(
          message:
              'This account has been deactivated. Please contact customer support.',
        );

        return;
      }
    }

    // ✅ SEND OTP
    final result =
        await ref
            .read(authRepositoryProvider)
            .sendOtp(e164Phone);

    result.fold(
      (failure) =>
          state = AuthError(
        message: failure.message,
      ),
      (verificationId) =>
          state = AuthCodeSent(
        verificationId:
            verificationId,
        phoneNumber:
            e164Phone,
      ),
    );

  } catch (e) {

    state = const AuthError(
      message:
          'Something went wrong. Please try again.',
    );
  }
}

  Future<void> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    state = const AuthOtpVerifying();

    final result = await ref
        .read(authRepositoryProvider)
        .verifyOtpAndSignIn(
          verificationId: verificationId,
          otp: otp,
        );

    result.fold(
      (failure) =>
          state = AuthError(message: failure.message),
      (user) {
        if (user == null) {
          state = AuthNewUser(
            uid: FirebaseAuth.instance.currentUser?.uid ?? '',
            phoneNumber:
                FirebaseAuth.instance.currentUser?.phoneNumber ??
                    '',
          );
        } else {
          state = AuthAuthenticated(user: user);
        }
      },
    );
  }

  Future<void> saveProfile({
    required String uid,
    required String phone,
    required String fullName,
    required String foodPreference,
    required String? email,
  }) async {
    state = const AuthLoading();

    final result = await ref
        .read(authRepositoryProvider)
        .saveUserProfile(
          uid: uid,
          phone: phone,
          fullName: fullName,
          foodPreference: foodPreference,
          email: email,
        );

    result.fold(
      (failure) =>
          state = AuthError(message: failure.message),
      (user) => state = AuthAuthenticated(user: user),
    );
  }

  Future<void> markWelcomeModalSeen(String uid) async {
    await ref
        .read(authRepositoryProvider)
        .markWelcomeModalSeen(uid);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthUnauthenticated();
  }

  void resetError() => state = const AuthUnauthenticated();
}