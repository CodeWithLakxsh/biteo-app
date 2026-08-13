// =============================================================
// lib/features/auth/presentation/providers/auth_providers.dart
// FIXED: BiteoUser → UserEntity
// FIXED: AuthRepository → IAuthRepository
// ADDED: Biteo Points Providers
// LOGIC UNCHANGED
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';

import 'auth_notifier.dart';
import 'auth_state.dart';

// ─────────────────────────────────────────────────────────────
// DATA LAYER
// ─────────────────────────────────────────────────────────────

final authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((ref) {

  return AuthRemoteDataSourceImpl(
    auth: ref.watch(
      firebaseAuthProvider,
    ),
    firestore: ref.watch(
      firestoreProvider,
    ),
  );
});

final authRepositoryProvider =
    Provider<IAuthRepository>((ref) {

  return AuthRepositoryImpl(
    dataSource: ref.watch(
      authRemoteDataSourceProvider,
    ),
  );
});

// ─────────────────────────────────────────────────────────────
// PRESENTATION LAYER
// ─────────────────────────────────────────────────────────────

/// Main auth state machine
final authNotifierProvider =
    NotifierProvider<
        AuthNotifier,
        AuthState>(() {

  return AuthNotifier();
});

/// Current logged-in user stream
final currentUserProvider =
    StreamProvider<UserEntity?>((ref) {

  return ref
      .watch(
        authRepositoryProvider,
      )
      .watchCurrentUser();
});

// =============================================================
// ⭐ BITEO POINTS PROVIDERS
// =============================================================

/// Current available Biteo points
final biteoPointsProvider =
    Provider<int>((ref) {

  final userAsync =
      ref.watch(
        currentUserProvider,
      );

  return userAsync.when(
    data: (user) =>
        user?.biteoPoints ?? 0,

    loading: () => 0,

    error: (_, __) => 0,
  );
});

/// Lifetime earned points
final lifetimeEarnedPointsProvider =
    Provider<int>((ref) {

  final userAsync =
      ref.watch(
        currentUserProvider,
      );

  return userAsync.when(
    data: (user) =>
        user?.pointsEarnedLifetime ??
        0,

    loading: () => 0,

    error: (_, __) => 0,
  );
});

/// Lifetime spent points
final lifetimeSpentPointsProvider =
    Provider<int>((ref) {

  final userAsync =
      ref.watch(
        currentUserProvider,
      );

  return userAsync.when(
    data: (user) =>
        user?.pointsSpentLifetime ??
        0,

    loading: () => 0,

    error: (_, __) => 0,
  );
});