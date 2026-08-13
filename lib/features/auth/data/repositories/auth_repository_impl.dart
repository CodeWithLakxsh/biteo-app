import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_failure.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';

import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl
    implements IAuthRepository {

  final AuthRemoteDataSource
      _dataSource;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource
        dataSource,
  }) : _dataSource = dataSource;

  // ✅🔥 FINAL FIX
  @override
  Future<
      Either<
          AppFailure,
          UserEntity>> getCurrentUser(
    String uid,
  ) async {

    try {

      final doc =
          await _dataSource
              .watchUserDocument(uid)
              .first;

      if (doc.exists &&
          doc.data() != null) {

        return Right(
          UserEntity.fromFirestore(
            doc.data()!,
            uid,
          ),
        );
      }

      // ✅ FALLBACK
      final firebaseUser =
          FirebaseAuth
              .instance
              .currentUser;

      if (firebaseUser != null) {

        return Right(
          UserEntity(
            uid: firebaseUser.uid,

            phone:
                firebaseUser
                        .phoneNumber ??
                    '',

            fullName: '',

            foodPreference: '',

            email:
                firebaseUser.email,

            isProfileComplete:
                false,

            createdAt:
                DateTime.now(),

            // ⭐ BITEO POINTS
            biteoPoints: 0,
            pointsEarnedLifetime:
                0,
            pointsSpentLifetime:
                0,
          ),
        );
      }

      return Left(
        AppFailure.server(),
      );

    } catch (e) {

      final firebaseUser =
          FirebaseAuth
              .instance
              .currentUser;

      // ✅ SAFE FALLBACK
      if (firebaseUser != null) {

        return Right(
          UserEntity(
            uid: firebaseUser.uid,

            phone:
                firebaseUser
                        .phoneNumber ??
                    '',

            fullName: '',

            foodPreference: '',

            email:
                firebaseUser.email,

            isProfileComplete:
                false,

            createdAt:
                DateTime.now(),

            // ⭐ BITEO POINTS
            biteoPoints: 0,
            pointsEarnedLifetime:
                0,
            pointsSpentLifetime:
                0,
          ),
        );
      }

      return Left(
        AppFailure.server(),
      );
    }
  }

  @override
  Future<
      Either<
          AppFailure,
          String>> sendOtp(
    String phoneNumber,
  ) async {

    try {

      final verificationId =
          await _dataSource.sendOtp(
        phoneNumber,
      );

      return Right(
        verificationId,
      );

    } on FirebaseAuthException catch (e) {

      return Left(
        AppFailure.fromFirebaseCode(
          e.code,
          e.message,
        ),
      );

    } catch (_) {

      return Left(
        AppFailure.server(),
      );
    }
  }

  @override
  Future<
      Either<
          AppFailure,
          UserEntity?>>
      verifyOtpAndSignIn({
    required String
        verificationId,

    required String otp,
  }) async {

    try {

      final userCredential =
          await _dataSource
              .verifyOtpAndSignIn(
        verificationId:
            verificationId,
        otp: otp,
      );

      final uid =
          userCredential.user?.uid;

      if (uid == null) {

        return Left(
          AppFailure.server(),
        );
      }

      final isComplete =
          await _dataSource
              .isUserProfileComplete(
        uid,
      );

      if (!isComplete) {

        return const Right(
          null,
        );
      }

      final doc =
          await _dataSource
              .watchUserDocument(uid)
              .first;

      if (!doc.exists ||
          doc.data() == null) {

        final firebaseUser =
            FirebaseAuth
                .instance
                .currentUser;

        if (firebaseUser != null) {

          return Right(
            UserEntity(
              uid:
                  firebaseUser.uid,

              phone:
                  firebaseUser
                          .phoneNumber ??
                      '',

              fullName: '',

              foodPreference: '',

              email:
                  firebaseUser.email,

              isProfileComplete:
                  false,

              createdAt:
                  DateTime.now(),

              // ⭐ BITEO POINTS
              biteoPoints: 0,
              pointsEarnedLifetime:
                  0,
              pointsSpentLifetime:
                  0,
            ),
          );
        }

        return const Right(
          null,
        );
      }

      return Right(
        UserEntity.fromFirestore(
          doc.data()!,
          uid,
        ),
      );

    } on FirebaseAuthException catch (e) {

      return Left(
        AppFailure.fromFirebaseCode(
          e.code,
          e.message,
        ),
      );

    } catch (_) {

      return Left(
        AppFailure.server(),
      );
    }
  }

  @override
  Future<
      Either<
          AppFailure,
          UserEntity>>
      saveUserProfile({

    required String uid,

    required String phone,

    required String fullName,

    required String
        foodPreference,

    required String? email,
  }) async {

    try {

      await _dataSource
          .createUserProfile(
        uid: uid,
        phone: phone,
        fullName: fullName,
        foodPreference:
            foodPreference,
        email: email,
      );

      final user = UserEntity(
        uid: uid,

        phone: phone,

        fullName: fullName,

        foodPreference:
            foodPreference,

        email: email,

        isProfileComplete:
            true,

        createdAt:
            DateTime.now(),

        // ⭐ BITEO POINTS
        biteoPoints: 0,
        pointsEarnedLifetime:
            0,
        pointsSpentLifetime:
            0,
      );

      return Right(user);

    } catch (_) {

      return Left(
        AppFailure.server(),
      );
    }
  }

  @override
  Future<
      Either<
          AppFailure,
          void>>
      markWelcomeModalSeen(
    String uid,
  ) async {

    try {

      await _dataSource
          .markWelcomeModalSeen(
        uid,
      );

      return const Right(
        null,
      );

    } catch (_) {

      return Left(
        AppFailure.server(),
      );
    }
  }

  @override
  Future<
      Either<
          AppFailure,
          void>> signOut() async {

    try {

      await _dataSource.signOut();

      return const Right(
        null,
      );

    } catch (_) {

      return Left(
        AppFailure.server(),
      );
    }
  }

  @override
  Stream<UserEntity?>
      watchCurrentUser() {

    return _dataSource
        .authStateChanges
        .asyncExpand(
      (firebaseUser) {

        if (firebaseUser == null) {

          return Stream.value(
            null,
          );
        }

        return _dataSource
            .watchUserDocument(
          firebaseUser.uid,
        ).map((doc) {

          if (!doc.exists ||
              doc.data() == null) {

            return UserEntity(
              uid:
                  firebaseUser.uid,

              phone:
                  firebaseUser
                          .phoneNumber ??
                      '',

              fullName: '',

              foodPreference: '',

              email:
                  firebaseUser.email,

              isProfileComplete:
                  false,

              createdAt:
                  DateTime.now(),

              // ⭐ BITEO POINTS
              biteoPoints: 0,
              pointsEarnedLifetime:
                  0,
              pointsSpentLifetime:
                  0,
            );
          }

          return UserEntity
              .fromFirestore(
            doc.data()!,
            firebaseUser.uid,
          );
        });
      },
    );
  }
}