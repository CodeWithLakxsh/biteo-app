// ============================================================
// lib/features/home/domain/entities/vendor_entity.dart
//
// FIX: Removed @freezed annotation and all `part` directives.
// Plain Dart immutable class with manual copyWith.
// No code generation required — compiles immediately.
// ============================================================

import 'package:intl/intl.dart';

class VendorEntity {
  final String id;
  final String businessName;
  final String legalEntityName;
  final String category;

  final String? brandLogoUrl;
  final String? coverImageUrl;

  // 🔥 FIX: default value to avoid crashes
  final String fssaiLicense;

  final String? gstin;
  final String? phoneNumber;

  final String fullAddress;
  final String city;
  final double lat;
  final double lng;

  // ── Vendor controls ────────────────────────────────
  final bool isActive;
  final bool isAcceptingOrders;

  // ✅ MANUAL FIREBASE OPEN/CLOSE CONTROL
  final bool isCurrentlyOpen;

  // ── Operations ─────────────────────────────────────
  final List<String> pickupModes;
  final int prepTimeMinutes;

  // ── Ratings ────────────────────────────────────────
  final double averageRating;
  final int totalRatings;

  // ── Tags ───────────────────────────────────────────
  final List<String> tags;

  // ── Distance ───────────────────────────────────────
  final double? distanceKm;

  // ── Meta ───────────────────────────────────────────
  final DateTime? createdAt;
  final Map<String, dynamic> operatingHours;

  const VendorEntity({
    required this.id,
    required this.businessName,
    required this.legalEntityName,
    required this.category,
    this.brandLogoUrl,
    this.coverImageUrl,
    this.fssaiLicense = '',
    this.gstin,
    this.phoneNumber,
    required this.fullAddress,
    required this.city,
    required this.lat,
    required this.lng,
    this.isActive = false,
    this.isAcceptingOrders = false,
    this.isCurrentlyOpen = true,
    this.pickupModes = const ['in_store'],
    this.prepTimeMinutes = 20,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.tags = const [],
    this.distanceKm,
    this.createdAt,
    this.operatingHours = const {},
  });

  // ── copyWith ───────────────────────────────────────
  VendorEntity copyWith({
    String? id,
    String? businessName,
    String? legalEntityName,
    String? category,
    String? brandLogoUrl,
    String? coverImageUrl,
    String? fssaiLicense,
    String? gstin,
    String? phoneNumber,
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
    double? distanceKm,
    DateTime? createdAt,
    Map<String, dynamic>? operatingHours,
  }) {
    return VendorEntity(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      legalEntityName: legalEntityName ?? this.legalEntityName,
      category: category ?? this.category,
      brandLogoUrl: brandLogoUrl ?? this.brandLogoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      fssaiLicense: fssaiLicense ?? this.fssaiLicense,
      gstin: gstin ?? this.gstin,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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
      distanceKm: distanceKm ?? this.distanceKm,
      createdAt: createdAt ?? this.createdAt,
      operatingHours: operatingHours ?? this.operatingHours,
    );
  }

  // ── Distance text ───────────────────────────────────
  String get distanceText {
    if (distanceKm == null) return '';

    if (distanceKm! < 1.0) {
      return '${(distanceKm! * 1000).round()} m away';
    }

    return '${distanceKm!.toStringAsFixed(1)} km away';
  }

  // ── Prep time ───────────────────────────────────────
  String get prepTimeText =>
      '~$prepTimeMinutes min';

  // ── Rating ──────────────────────────────────────────
  String get ratingText =>
      averageRating > 0
          ? averageRating.toStringAsFixed(1)
          : 'New';

  // ── Veg options ─────────────────────────────────────
  bool get hasVegOptions =>
      tags.any(
        (t) =>
            t.toLowerCase().contains('veg'),
      );

  // ── Joining date ────────────────────────────────────
  String get joiningDateText {
    if (createdAt == null) {
      return 'Unavailable';
    }

    return DateFormat('MMM yyyy')
        .format(createdAt!);
  }

  // ── FSSAI display ───────────────────────────────────
  String get fssaiDisplay =>
      fssaiLicense.trim().isEmpty
          ? 'Not available'
          : fssaiLicense;

  // ── GST display (masked) ────────────────────────────
  String get gstDisplay {
    if (gstin == null ||
        gstin!.trim().isEmpty) {
      return 'Unavailable';
    }

    final gst = gstin!.trim();

    if (gst.length <= 5) {
      return gst;
    }

    final start =
        gst.substring(0, 2);

    final end = gst.substring(
      gst.length - 3,
    );

    final maskedLength =
        gst.length - 5;

    return '$start${'X' * maskedLength}$end';
  }

  // ── Order eligibility ───────────────────────────────
  bool get canAcceptOrders =>
      isActive &&
      isAcceptingOrders &&
      isCurrentlyOpen;

  // ── Operating hours available ───────────────────────
  bool get hasOperatingHours =>
      operatingHours.isNotEmpty;

  // ── Equality ────────────────────────────────────────
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorEntity &&
          id == other.id &&
          businessName == other.businessName &&
          category == other.category;

  @override
  int get hashCode =>
      id.hashCode ^
      businessName.hashCode ^
      category.hashCode;

  @override
  String toString() =>
      'VendorEntity(id: $id, businessName: $businessName)';
}
