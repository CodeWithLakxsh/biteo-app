// =============================================================
// lib/features/auth/domain/failures/auth_failure.dart
// Simple failure model for auth layer
// =============================================================

class AuthFailure {
  final String message;

  const AuthFailure(this.message);

  @override
  String toString() => message;
}