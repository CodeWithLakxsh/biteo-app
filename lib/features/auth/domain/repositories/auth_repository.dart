// =============================================================
// lib/features/auth/domain/repositories/auth_repository.dart
// The abstract contract the domain layer uses to talk to the data
// layer. The domain layer NEVER imports firebase_auth. It only
// ever depends on this interface.
// =============================================================

import 'package:dartz/dartz.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/biteo_user.dart';

abstract class AuthRepository {
  /// Triggers Firebase to send a 6-digit OTP to [phoneNumber].
  /// Returns the [verificationId] (a server-generated token needed
  /// to verify the OTP). Returns AppFailure on any error.
  Future<Either<AppFailure, String>> sendOtp(String phoneNumber);

  /// Verifies the OTP. On success:
  ///   - Returns [BiteoUser] if this is a returning user with a complete profile.
  ///   - Returns null if this is a NEW user (triggers profile setup screen).
  Future<Either<AppFailure, BiteoUser?>> verifyOtpAndSignIn({
    required String verificationId,
    required String otp,
  });

  /// Creates the user's profile document in Firestore.
  /// Called once, after OTP verification, for new users.
  Future<Either<AppFailure, BiteoUser>> saveUserProfile({
    required String uid,
    required String phone,
    required String fullName,
    required String? email,
  });

  /// Sets `hype_engine.has_seen_welcome_modal = true` in Firestore.
  /// Called when the user dismisses the "Delivery Unlock" modal.
  Future<Either<AppFailure, void>> markWelcomeModalSeen(String uid);

  /// Signs the user out of Firebase Auth.
  Future<Either<AppFailure, void>> signOut();

  /// Real-time stream of the current user's full profile.
  /// Combines Firebase Auth state with the Firestore user document.
  /// Emits null when the user signs out.
  Stream<BiteoUser?> watchCurrentUser();
}