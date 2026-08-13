import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/vendor_entity.dart';
import '../../domain/repositories/i_vendor_repository.dart';
import '../models/vendor_model.dart';

class VendorRepositoryImpl
    implements IVendorRepository {
  final FirebaseFirestore _db;
  final Logger _log;

  static const _collection = 'vendors';

  VendorRepositoryImpl({
    FirebaseFirestore? db,
  })  : _db = db ?? FirebaseFirestore.instance,
        _log = Logger(
          printer: PrettyPrinter(
            methodCount: 0,
          ),
        );

  // ==========================================================
  // WATCH NEARBY VENDORS
  // ==========================================================

  @override
  Stream<List<VendorEntity>>
      watchNearbyVendors({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) {
    _log.i(
      '[Vendors] Watching vendors within '
      '${radiusKm}km of ($lat, $lng)',
    );

    final center = GeoFirePoint(
      GeoPoint(lat, lng),
    );

    // ======================================================
    // ✅ FIXED TYPE ISSUE
    // ======================================================

    final CollectionReference<
            Map<String, dynamic>>
        collectionRef =
        _db.collection(_collection);

    return GeoCollectionReference<
            Map<String, dynamic>>(
      collectionRef,
    ).subscribeWithin(
      center: center,

      radiusInKm: radiusKm,

      field: 'geo',

      // ====================================================
      // SAFE GEOPOINT PARSER
      // ====================================================

      geopointFrom: (data) {
        try {
          final geo = data['geo'];

          if (geo is Map<String, dynamic>) {
            final gp = geo['geopoint'];

            if (gp is GeoPoint) {
              return gp;
            }
          }

          _log.e(
            '❌ GEOPOINT MISSING OR WRONG FORMAT',
          );

          _log.e(data);

          throw Exception(
            'GeoPoint missing in vendor document',
          );
        } catch (e) {
          _log.e(
            '❌ Error parsing geopoint',
            error: e,
          );

          rethrow;
        }
      },

      strictMode: true,
    ).map((snapshots) {
      _log.i(
        '📦 RAW SNAPSHOTS: ${snapshots.length}',
      );

      final entities = snapshots
          .where(
            (snap) =>
                snap.exists &&
                snap.data() != null,
          )
          .map((snap) {
        try {
          final data = snap.data();

          if (data == null) {
            return null;
          }

          _log.d(
            '📄 DOC DATA: $data',
          );

          // ================================================
          // SAFE MODEL PARSING
          // ================================================

          final model =
              VendorModel.fromFirestore(
            snap as DocumentSnapshot<
                Map<String, dynamic>>,
          );

          // ================================================
          // OPTIONAL ACTIVE FILTER
          // ================================================

          if (!model.isActive) {
            _log.w(
              '⚠️ Skipping inactive vendor: '
              '${model.businessName}',
            );

            return null;
          }

          final distanceKm =
              _haversineKm(
            lat,
            lng,
            model.lat,
            model.lng,
          );

          _log.d(
            '📍 Vendor: '
            '${model.businessName} '
            '| Distance: $distanceKm km',
          );

          return model.toEntity(
            distanceKm: distanceKm,
          );
        } catch (e) {
          _log.e(
            '❌ Error parsing vendor',
            error: e,
          );

          return null;
        }
      }).whereType<VendorEntity>().toList();

      // ====================================================
      // SORT BY DISTANCE
      // ====================================================

      entities.sort(
        (a, b) =>
            (a.distanceKm ?? 999)
                .compareTo(
          b.distanceKm ?? 999,
        ),
      );

      _log.i(
        '✅ FINAL VENDORS COUNT: '
        '${entities.length}',
      );

      return entities;
    });
  }

  // ==========================================================
  // GET SINGLE VENDOR
  // ==========================================================

  @override
  Future<VendorEntity?> getVendorById(
    String vendorId,
  ) async {
    try {
      final snap = await _db
          .collection(_collection)
          .doc(vendorId)
          .get();

      if (!snap.exists ||
          snap.data() == null) {
        return null;
      }

      final model =
          VendorModel.fromFirestore(
        snap,
      );

      return model.toEntity();
    } catch (e) {
      _log.e(
        '[Vendors] Error fetching vendor '
        '$vendorId',
        error: e,
      );

      return null;
    }
  }

  // ==========================================================
  // HAVERSINE DISTANCE
  // ==========================================================

  double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;

    final dLat = _toRad(
      lat2 - lat1,
    );

    final dLng = _toRad(
      lng2 - lng1,
    );

    final a =
        math.sin(dLat / 2) *
                math.sin(dLat / 2) +
            math.cos(
                  _toRad(lat1),
                ) *
                math.cos(
                  _toRad(lat2),
                ) *
                math.sin(dLng / 2) *
                math.sin(dLng / 2);

    final c = 2 *
        math.atan2(
          math.sqrt(a),
          math.sqrt(1 - a),
        );

    return r * c;
  }

  double _toRad(double deg) {
    return deg *
        (math.pi / 180.0);
  }
}