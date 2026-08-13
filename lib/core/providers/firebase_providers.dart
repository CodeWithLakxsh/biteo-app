// =============================================================
// lib/core/providers/firebase_providers.dart
// Riverpod providers for every Firebase singleton.
// This is the ONLY place FirebaseAuth.instance appears.
// All other code must use these providers. This enables mocking
// in tests without changing any business logic.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// Streams the raw Firebase User object.
/// null  → user is logged out.
/// User  → user is logged in (profile may or may not be complete).
/// This is the lowest-level auth signal — the router subscribes to it.
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});