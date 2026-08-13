// ============================================================
// lib/features/address/domain/repositories/i_address_repository.dart
// ============================================================
import 'package:dartz/dartz.dart';
import '../entities/address_entity.dart';

abstract class AddressFailure {
  const AddressFailure();
  String get userMessage;
  const factory AddressFailure.saveError({String? message}) = _SaveError;
  const factory AddressFailure.deleteError() = _DeleteError;
  const factory AddressFailure.fetchError() = _FetchError;
  const factory AddressFailure.unknown() = _UnknownError;
}

final class _SaveError extends AddressFailure {
  final String? message;
  const _SaveError({this.message});
  @override
  String get userMessage => 'Could not save address. Please try again.';
}

final class _DeleteError extends AddressFailure {
  const _DeleteError();
  @override
  String get userMessage => 'Could not delete address.';
}

final class _FetchError extends AddressFailure {
  const _FetchError();
  @override
  String get userMessage => 'Could not load saved addresses.';
}

final class _UnknownError extends AddressFailure {
  const _UnknownError();
  @override
  String get userMessage => 'Something went wrong. Please try again.';
}

abstract class IAddressRepository {
  Stream<List<AddressEntity>> watchAddresses(String userId);
  Future<Either<AddressFailure, AddressEntity>> saveAddress({
    required String userId,
    required AddressEntity address,
  });
  Future<Either<AddressFailure, Unit>> deleteAddress({
    required String userId,
    required String addressId,
  });
  Future<Either<AddressFailure, Unit>> setDefaultAddress({
    required String userId,
    required String addressId,
  });
}
