// ============================================================
// lib/features/auth/presentation/providers/auth_state.dart
//
// Pure auth sealed class hierarchy.
// No @freezed. No code generation needed.
// Factory constructors preserved so AuthNotifier call sites 
// like AuthState.authenticated(...) don't break.
// CTO FIX: Aligned factory constructor parameters with subclasses
// and removed unused missing imports.
// ============================================================
import '../../domain/entities/user_entity.dart';

// ── Base sealed class ─────────────────────────────────────────
sealed class AuthState {
  const AuthState();

  // Factory constructors — mirror the old @freezed API exactly.
  const factory AuthState.initial() = AuthStateInitial;

  const factory AuthState.loading({String? message}) = AuthStateLoading;

  const factory AuthState.codeSent({
    required String verificationId,
    required String phoneNumber,
    int? resendToken,
  }) = AuthStateCodeSent;

  const factory AuthState.otpVerifying() = AuthStateOtpVerifying;

  const factory AuthState.newUser({
    required String uid,
    required String phoneNumber,
  }) = AuthStateNewUser;

  const factory AuthState.authenticated({
    required UserEntity user,
    bool isNewUser,
  }) = AuthStateAuthenticated;

  const factory AuthState.error({
    required String message,
  }) = AuthStateError;

  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;

  // ✅ 🔥 FINAL FIX: ADD THIS (VERY IMPORTANT)
  const factory AuthState.checking() = AuthStateChecking;
}

// ── Concrete subclasses (For 'is' checks in UI) ───────────────

final class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

final class AuthStateLoading extends AuthState {
  final String? message;
  const AuthStateLoading({this.message});
}

final class AuthStateCodeSent extends AuthState {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;
  const AuthStateCodeSent({
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });
}

final class AuthStateOtpVerifying extends AuthState {
  const AuthStateOtpVerifying();
}

final class AuthStateNewUser extends AuthState {
  final String uid;
  final String phoneNumber;
  const AuthStateNewUser({
    required this.uid,
    required this.phoneNumber,
  });
}

final class AuthStateAuthenticated extends AuthState {
  final UserEntity user;
  final bool isNewUser;
  const AuthStateAuthenticated({
    required this.user,
    this.isNewUser = false,
  });
}

final class AuthStateError extends AuthState {
  final String message;
  const AuthStateError({required this.message});
}

final class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

// ✅ 🔥 NEW STATE (CRITICAL FOR FIX)
final class AuthStateChecking extends AuthState {
  const AuthStateChecking();
}

// ── MASTERSTROKE: Aliases for backwards compatibility ─────────
typedef AuthInitial = AuthStateInitial;
typedef AuthLoading = AuthStateLoading;
typedef AuthCodeSent = AuthStateCodeSent;
typedef AuthOtpVerifying = AuthStateOtpVerifying;
typedef AuthNewUser = AuthStateNewUser;
typedef AuthAuthenticated = AuthStateAuthenticated;
typedef AuthError = AuthStateError;
typedef AuthUnauthenticated = AuthStateUnauthenticated;

// ✅ Alias for new state
typedef AuthChecking = AuthStateChecking;