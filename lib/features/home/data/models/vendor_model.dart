// ============================================================
// lib/features/home/data/models/vendor_model.dart
//
// FIX: Removed @freezed annotation and all `part` directives.
// Plain Dart immutable class with manual copyWith.
// No code generation required — compiles immediately.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/vendor_entity.dart';

class VendorModel {
  final String id;
  final String businessName;
  final String category;
  final String fullAddress;
  final String city;

  // ── Geo ─────────────────────────────────────────────
  final double lat;
  final double lng;

  // ── Operations ──────────────────────────────────────
  final bool isActive;
  final bool isAcceptingOrders;
  final bool isCurrentlyOpen;

  final List<String> pickupModes;
  final int prepTimeMinutes;

  // ── Ratings ─────────────────────────────────────────
  final double averageRating;
  final int totalRatings;

  // ── Tags ────────────────────────────────────────────
  final List<String> tags;

  // ── Media ───────────────────────────────────────────
  final String? imageUrl;
  final String? coverImageUrl;
  final String? brandLogoUrl;

  // ── Created ─────────────────────────────────────────
  final DateTime? createdAt;

  // ── Legal ───────────────────────────────────────────
  final String? fssaiLicense;
  final String? legalEntityName;
  final String? gstin;

  // ── Contact ─────────────────────────────────────────
  final String? phoneNumber;

  // ── Hours ───────────────────────────────────────────
  final Map<String, dynamic>? operatingHours;

  const VendorModel({
    required this.id,
    required this.businessName,
    required this.category,
    required this.fullAddress,
    required this.city,
    required this.lat,
    required this.lng,
    required this.isActive,
    required this.isAcceptingOrders,
    required this.isCurrentlyOpen,
    required this.pickupModes,
    required this.prepTimeMinutes,
    required this.averageRating,
    required this.totalRatings,
    this.tags = const [],
    this.imageUrl,
    this.coverImageUrl,
    this.brandLogoUrl,
    this.createdAt,
    this.fssaiLicense,
    this.legalEntityName,
    this.gstin,
    this.phoneNumber,
    this.operatingHours,
  });

  // ── copyWith ────────────────────────────────────────
  VendorModel copyWith({
    String? id,
    String? businessName,
    String? category,
    String? fullAddress,
    String? city,
    double? lat,
    double? lng,
    bool? isActive,
    bool? isAcceptingOrders,
    bool? isCurrentlyOpen,
    List<String>? pickupModes,
    int? prepTimeMinutes,
    double? averageRating,
    int? totalRatings,
    List<String>? tags,
    String? imageUrl,
    String? coverImageUrl,
    String? brandLogoUrl,
    DateTime? createdAt,
    String? fssaiLicense,
    String? legalEntityName,
    String? gstin,
    String? phoneNumber,
    Map<String, dynamic>? operatingHours,
  }) {
    return VendorModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      fullAddress: fullAddress ?? this.fullAddress,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isActive: isActive ?? this.isActive,
      isAcceptingOrders: isAcceptingOrders ?? this.isAcceptingOrders,
      isCurrentlyOpen: isCurrentlyOpen ?? this.isCurrentlyOpen,
      pickupModes: pickupModes ?? this.pickupModes,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      brandLogoUrl: brandLogoUrl ?? this.brandLogoUrl,
      createdAt: createdAt ?? this.createdAt,
      fssaiLicense: fssaiLicense ?? this.fssaiLicense,
      legalEntityName: legalEntityName ?? this.legalEntityName,
      gstin: gstin ?? this.gstin,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      operatingHours: operatingHours ?? this.operatingHours,
    );
  }

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

  // ── Equality ────────────────────────────────────────
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorModel &&
          id == other.id &&
          businessName == other.businessName;

  @override
  int get hashCode =>
      id.hashCode ^ businessName.hashCode;

  @override
  String toString() =>
      'VendorModel(id: $id, businessName: $businessName)';
}