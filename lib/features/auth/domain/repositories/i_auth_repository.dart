// =============================================================
// FILE: lib/features/auth/domain/repositories/i_auth_repository.dart
// CLEAN VERSION (FINAL FIXED)
// =============================================================

import 'package:dartz/dartz.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/user_entity.dart';

abstract class IAuthRepository {
  /// Triggers Firebase to send a 6-digit OTP to [phoneNumber].
  /// Returns the [verificationId].
  Future<Either<AppFailure, String>> sendOtp(String phoneNumber);

  /// Verifies OTP and signs in user.
  /// Returns:
  /// - UserEntity if existing user
  /// - null if new user
  Future<Either<AppFailure, UserEntity?>> verifyOtpAndSignIn({
    required String verificationId,
    required String otp,
  });

  /// Creates user profile in Firestore
  Future<Either<AppFailure, UserEntity>> saveUserProfile({
    required String uid,
    required String phone,
    required String fullName,
    required String foodPreference,
    required String? email,
  });

  /// Marks welcome modal as seen
  Future<Either<AppFailure, void>> markWelcomeModalSeen(String uid);

  /// Sign out
  Future<Either<AppFailure, void>> signOut();

  /// Stream current user
  Stream<UserEntity?> watchCurrentUser();

  // ✅🔥 FINAL FIX: ADD THIS METHOD (CRITICAL FOR PERSISTENT LOGIN)
  Future<Either<AppFailure, UserEntity>> getCurrentUser(String uid);
}