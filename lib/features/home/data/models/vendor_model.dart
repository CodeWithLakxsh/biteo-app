import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/vendor_entity.dart';

part 'vendor_model.freezed.dart';
part 'vendor_model.g.dart';

@freezed
abstract class VendorModel with _$VendorModel {
  const VendorModel._();

  const factory VendorModel({
    required String id,
    required String businessName,
    required String category,
    required String fullAddress,
    required String city,

    // ── Geo ───────────────────────────
    required double lat,
    required double lng,

    // ── Operations ────────────────────
    required bool isActive,
    required bool isAcceptingOrders,
    required bool isCurrentlyOpen,

    required List<String> pickupModes,
    required int prepTimeMinutes,

    // ── Ratings ───────────────────────
    required double averageRating,
    required int totalRatings,

    // ── Tags ──────────────────────────
    @Default(<String>[]) List<String> tags,

    // ── Media ─────────────────────────
    String? imageUrl,
    String? coverImageUrl,
    String? brandLogoUrl,

    // ── Created ───────────────────────
    DateTime? createdAt,

    // ── Legal ─────────────────────────
    String? fssaiLicense,
    String? legalEntityName,
    String? gstin,

    // ── Contact ───────────────────────
    String? phoneNumber,

    // ── Hours ─────────────────────────
    Map<String, dynamic>? operatingHours,
  }) = _VendorModel;

  factory VendorModel.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$VendorModelFromJson(json);

  // ==========================================================
  // 🔥 FIRESTORE PARSER
  // ==========================================================
  factory VendorModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();

    if (d == null) {
      throw Exception(
        'Vendor document is null',
      );
    }

    // ── Nested Maps ───────────────────
    final identity =
        d['identity'] as Map<String, dynamic>? ??
            {};

    final ops =
        d['operations'] as Map<String, dynamic>? ??
            {};

    final ratings =
        d['ratings'] as Map<String, dynamic>? ??
            {};

    final location =
        d['location'] as Map<String, dynamic>? ??
            {};

    final geo =
        d['geo'] as Map<String, dynamic>? ??
            {};

    // ── Created Date ──────────────────
    final createdAt =
        (d['createdAt'] as Timestamp?)
            ?.toDate();

    // ==========================================================
    // 🔥 FINAL STANDARDIZED GEO
    // ONLY geo.geopoint IS SOURCE OF TRUTH
    // ==========================================================
    final geopoint =
        geo['geopoint'];

    if (geopoint == null ||
        geopoint is! GeoPoint) {
      debugPrint(
        '❌ Missing geo.geopoint for vendor: ${doc.id}',
      );

      throw Exception(
        'Vendor missing geo.geopoint',
      );
    }

    final lat =
        geopoint.latitude.toDouble();

    final lng =
        geopoint.longitude.toDouble();

    return VendorModel(
      id: doc.id,

      // ── Identity ────────────────────
      businessName:
          (identity['business_name'] ??
                  d['businessName'] ??
                  '')
              .toString(),

      legalEntityName:
          (identity['legal_entity_name'] ??
                  d['legalEntityName'] ??
                  '')
              .toString(),

      // ── Category ────────────────────
      category:
          (d['category'] ?? '')
              .toString(),

      // ── Location ────────────────────
      fullAddress:
          (location['full_address'] ??
                  d['fullAddress'] ??
                  '')
              .toString(),

      city:
          (location['city'] ??
                  d['city'] ??
                  '')
              .toString(),

      lat: lat,
      lng: lng,

      // ── Operations ──────────────────
      isActive:
          ops['is_active'] ??
              d['isActive'] ??
              true,

      isAcceptingOrders:
          ops['is_accepting_orders'] ??
              d['isAcceptingOrders'] ??
              true,

      isCurrentlyOpen:
          d['isCurrentlyOpen'] ??
              ops['is_currently_open'] ??
              true,

      pickupModes:
          List<String>.from(
        ops['pickup_modes'] ??
            d['pickupModes'] ??
            [],
      ),

      prepTimeMinutes:
          ((ops['prep_time_minutes'] ??
                      d['prepTimeMinutes'] ??
                      0)
                  as num)
              .toInt(),

      // ── Ratings ─────────────────────
      averageRating:
          ((ratings['average'] ??
                      d['averageRating'] ??
                      0)
                  as num)
              .toDouble(),

      totalRatings:
          ((ratings['total_count'] ??
                      d['totalRatings'] ??
                      0)
                  as num)
              .toInt(),

      // ── Tags ────────────────────────
      tags:
          List<String>.from(
        d['tags'] ?? [],
      ),

      // ── Media ───────────────────────
      imageUrl:
          d['imageUrl']
              ?.toString(),

      coverImageUrl:
          d['coverImageUrl']
              ?.toString(),

      brandLogoUrl:
          d['brandLogoUrl']
              ?.toString(),

      // ── Created ─────────────────────
      createdAt: createdAt,

      // ── Legal ───────────────────────
      fssaiLicense:
          d['fssaiLicense'] == null
              ? ''
              : d['fssaiLicense'] is int
                  ? (d['fssaiLicense']
                          as int)
                      .toString()
                  : d['fssaiLicense']
                      .toString(),

      gstin:
          d['gstin']
              ?.toString(),

      // ── Phone ───────────────────────
      phoneNumber:
          d['phoneNumber']
              ?.toString(),

      // ── Hours ───────────────────────
      operatingHours:
          (d['operatingHours']
                  as Map<String, dynamic>?) ??
              const {},
    );
  }

  // ==========================================================
  // 🔥 FIRESTORE EXPORT
  // ==========================================================
  Map<String, dynamic> toFirestore() {
    return {
      // ── Basic ───────────────────────
      'businessName':
          businessName,

      'category': category,

      // ── Media ───────────────────────
      'imageUrl': imageUrl,
      'coverImageUrl':
          coverImageUrl,
      'brandLogoUrl':
          brandLogoUrl,

      // ── Legal ───────────────────────
      'fssaiLicense':
          fssaiLicense,
      'legalEntityName':
          legalEntityName,
      'gstin': gstin,

      // ── Phone ───────────────────────
      'phoneNumber':
          phoneNumber,

      // ── Tags ────────────────────────
      'tags': tags,

      // ── Created ─────────────────────
      'createdAt': createdAt,

      // ── Operating Hours ─────────────
      'operatingHours':
          operatingHours,

      // ======================================================
      // 🔥 STANDARDIZED NESTED STRUCTURE
      // ======================================================

      'identity': {
        'business_name':
            businessName,
        'legal_entity_name':
            legalEntityName,
      },

      'location': {
        'full_address':
            fullAddress,
        'city': city,
      },

      'operations': {
        'is_active': isActive,
        'is_accepting_orders':
            isAcceptingOrders,
        'is_currently_open':
            isCurrentlyOpen,
        'pickup_modes':
            pickupModes,
        'prep_time_minutes':
            prepTimeMinutes,
      },

      'ratings': {
        'average':
            averageRating,
        'total_count':
            totalRatings,
      },

      // ======================================================
      // 🔥 ONLY THIS GEO STRUCTURE
      // ======================================================
      'geo': {
        'geopoint':
            GeoPoint(lat, lng),
      },
    };
  }

  // ==========================================================
  // 🔥 DOMAIN CONVERSION
  // ==========================================================
  VendorEntity toEntity({
    double? distanceKm,
  }) =>
      VendorEntity(
        id: id,
        businessName:
            businessName,
        category: category,

        // ── Legal ──────────────────────
        legalEntityName:
            legalEntityName ??
                '',

        brandLogoUrl:
            brandLogoUrl,

        // prefer cover image
        coverImageUrl:
            coverImageUrl ??
                imageUrl,

        fssaiLicense:
            fssaiLicense ??
                '',

        gstin: gstin,

        // ── Phone ──────────────────────
        phoneNumber:
            phoneNumber,

        // ── Location ───────────────────
        fullAddress:
            fullAddress,

        city: city,

        lat: lat,
        lng: lng,

        // ── Operations ─────────────────
        isActive:
            isActive,

        isAcceptingOrders:
            isAcceptingOrders,

        isCurrentlyOpen:
            isCurrentlyOpen,

        pickupModes:
            pickupModes,

        prepTimeMinutes:
            prepTimeMinutes,

        // ── Ratings ────────────────────
        averageRating:
            averageRating,

        totalRatings:
            totalRatings,

        // ── Misc ───────────────────────
        tags: tags,

        distanceKm:
            distanceKm,

        // ── Created ────────────────────
        createdAt:
            createdAt,

        operatingHours:
            operatingHours ??
                const {},
      );
}