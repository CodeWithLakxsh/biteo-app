// =============================================================
// lib/core/errors/app_failure.dart
// The single error type for the entire app.
// Repositories return Either<AppFailure, T> — they never throw.
// The UI layer receives a human-readable message, never a stack trace.
// =============================================================

class AppFailure {
  final String message;
  final String? code;

  const AppFailure(this.message, {this.code});

  // ── Named constructors for common cases ─────────────────
  factory AppFailure.network() => const AppFailure(
    'No internet connection. Please check your network.',
    code: 'network-error',
  );

  factory AppFailure.server() => const AppFailure(
    'Something went wrong on our end. Please try again.',
    code: 'server-error',
  );

  factory AppFailure.invalidOtp() => const AppFailure(
    'Incorrect OTP. Please check and try again.',
    code: 'invalid-verification-code',
  );

  factory AppFailure.otpExpired() => const AppFailure(
    'This OTP has expired. Please request a new one.',
    code: 'session-expired',
  );

  factory AppFailure.tooManyRequests() => const AppFailure(
    'Too many attempts. Please wait a few minutes.',
    code: 'too-many-requests',
  );

  factory AppFailure.invalidPhoneNumber() => const AppFailure(
    'This phone number doesn\'t look right. Check and retry.',
    code: 'invalid-phone-number',
  );

  /// Maps raw Firebase Auth error codes to our friendly messages.
  factory AppFailure.fromFirebaseCode(String code, [String? rawMessage]) {
    switch (code) {
      case 'invalid-verification-code':
        return AppFailure.invalidOtp();
      case 'session-expired':
        return AppFailure.otpExpired();
      case 'too-many-requests':
        return AppFailure.tooManyRequests();
      case 'invalid-phone-number':
        return AppFailure.invalidPhoneNumber();
      case 'network-request-failed':
        return AppFailure.network();
      default:
        return AppFailure(
          rawMessage ?? 'Authentication failed. Please try again.',
          code: code,
        );
    }
  }

  @override
  String toString() => 'AppFailure[$code]: $message';
}