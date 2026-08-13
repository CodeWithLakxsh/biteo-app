import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/i_address_repository.dart';

class AddressRepositoryImpl implements IAddressRepository {
  final FirebaseFirestore _db;
  final Logger _log;

  AddressRepositoryImpl({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance,
        _log = Logger(printer: PrettyPrinter(methodCount: 0));

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('users').doc(userId).collection('addresses');

  @override
  Stream<List<AddressEntity>> watchAddresses(String userId) {
    return _col(userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => _fromDoc(doc))
            .whereType<AddressEntity>()
            .toList());
  }

  @override
  Future<Either<AddressFailure, AddressEntity>> saveAddress({
    required String userId,
    required AddressEntity address,
  }) async {
    try {
      // ✅ FINAL FIX: STRICT ID USAGE
      final id = address.id?.isNotEmpty == true
          ? address.id!
          : const Uuid().v4();

      final updatedAddress = address.copyWith(
        id: id,
        createdAt: address.createdAt ?? DateTime.now(),
      );

      final data = _toMap(updatedAddress);

      // ✅ ALWAYS overwrite SAME document
      await _col(userId)
          .doc(id)
          .set(data, SetOptions(merge: true));

      _log.i('[Address] Saved/Updated: $id for user $userId');

      return right(updatedAddress);
    } catch (e) {
      _log.e('[Address] Save error', error: e);
      return left(AddressFailure.saveError(message: e.toString()));
    }
  }

  @override
  Future<Either<AddressFailure, Unit>> deleteAddress({
    required String userId,
    required String addressId,
  }) async {
    try {
      await _col(userId).doc(addressId).delete();
      _log.i('[Address] Deleted: $addressId');
      return right(unit);
    } catch (e) {
      _log.e('[Address] Delete error', error: e);
      return left(const AddressFailure.deleteError());
    }
  }

  @override
  Future<Either<AddressFailure, Unit>> setDefaultAddress({
    required String userId,
    required String addressId,
  }) async {
    try {
      final batch = _db.batch();
      final all = await _col(userId).get();

      for (final doc in all.docs) {
        batch.update(doc.reference, {'is_default': false});
      }

      batch.update(_col(userId).doc(addressId), {'is_default': true});

      await batch.commit();
      return right(unit);
    } catch (e) {
      _log.e('[Address] SetDefault error', error: e);
      return left(const AddressFailure.unknown());
    }
  }

  Map<String, dynamic> _toMap(AddressEntity a) => {
        'id': a.id,
        'label': a.label,
        'full_address': a.fullAddress,
        if (a.flatHouseNo != null) 'flat_house_no': a.flatHouseNo,
        if (a.floor != null) 'floor': a.floor,
        if (a.landmark != null) 'landmark': a.landmark,
        if (a.buildingName != null) 'building_name': a.buildingName,
        'lat': a.lat,
        'lng': a.lng,
        'geohash': a.geohash,
        'is_default': a.isDefault,
        if (a.contactName != null) 'contact_name': a.contactName,
        if (a.contactPhone != null) 'contact_phone': a.contactPhone,
        'created_at': a.createdAt != null
            ? Timestamp.fromDate(a.createdAt!)
            : FieldValue.serverTimestamp(),
      };

  AddressEntity? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final d = doc.data();
      if (d == null) return null;

      return AddressEntity(
        id: doc.id,
        label: d['label'] as String? ?? 'other',
        fullAddress: d['full_address'] as String? ?? '',
        flatHouseNo: d['flat_house_no'] as String?,
        floor: d['floor'] as String?,
        landmark: d['landmark'] as String?,
        buildingName: d['building_name'] as String?,
        lat: (d['lat'] as num?)?.toDouble() ?? 0,
        lng: (d['lng'] as num?)?.toDouble() ?? 0,
        geohash: d['geohash'] as String? ?? '',
        isDefault: d['is_default'] as bool? ?? false,
        contactName: d['contact_name'] as String?,
        contactPhone: d['contact_phone'] as String?,
        createdAt: d['created_at'] is Timestamp
            ? (d['created_at'] as Timestamp).toDate()
            : null,
      );
    } catch (e) {
      return null;
    }
  }
}