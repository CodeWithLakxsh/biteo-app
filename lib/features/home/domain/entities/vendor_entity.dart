import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'vendor_entity.freezed.dart';
part 'vendor_entity.g.dart';

@freezed
abstract class VendorEntity with _$VendorEntity {
  const VendorEntity._();

  const factory VendorEntity({
    required String id,
    required String businessName,
    required String legalEntityName,
    required String category,

    String? brandLogoUrl,
    String? coverImageUrl,

    // 🔥 FIX: default value to avoid crashes
    @Default('') String fssaiLicense,

    String? gstin,
    String? phoneNumber,

    required String fullAddress,
    required String city,
    required double lat,
    required double lng,

    // ─────────────────────────────────────────────
    // Vendor controls
    // ─────────────────────────────────────────────
    @Default(false) bool isActive,

    @Default(false)
    bool isAcceptingOrders,

    // ✅ MANUAL FIREBASE OPEN/CLOSE CONTROL
    @Default(true)
    bool isCurrentlyOpen,

    // ─────────────────────────────────────────────
    // Operations
    // ─────────────────────────────────────────────
    @Default(<String>['in_store'])
    List<String> pickupModes,

    @Default(20)
    int prepTimeMinutes,

    // ─────────────────────────────────────────────
    // Ratings
    // ─────────────────────────────────────────────
    @Default(0.0)
    double averageRating,

    @Default(0)
    int totalRatings,

    // ─────────────────────────────────────────────
    // Tags
    // ─────────────────────────────────────────────
    @Default(<String>[])
    List<String> tags,

    // ─────────────────────────────────────────────
    // Distance
    // ─────────────────────────────────────────────
    double? distanceKm,

    // ─────────────────────────────────────────────
    // Meta
    // ─────────────────────────────────────────────
    DateTime? createdAt,

    @Default(<String, dynamic>{})
    Map<String, dynamic> operatingHours,
  }) = _VendorEntity;

  factory VendorEntity.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$VendorEntityFromJson(json);

  // ─────────────────────────────────────────────
  // Distance text
  // ─────────────────────────────────────────────
  String get distanceText {
    if (distanceKm == null) return '';

    if (distanceKm! < 1.0) {
      return '${(distanceKm! * 1000).round()} m away';
    }

    return '${distanceKm!.toStringAsFixed(1)} km away';
  }

  // ─────────────────────────────────────────────
  // Prep time
  // ─────────────────────────────────────────────
  String get prepTimeText =>
      '~$prepTimeMinutes min';

  // ─────────────────────────────────────────────
  // Rating
  // ─────────────────────────────────────────────
  String get ratingText =>
      averageRating > 0
          ? averageRating.toStringAsFixed(1)
          : 'New';

  // ─────────────────────────────────────────────
  // Veg options
  // ─────────────────────────────────────────────
  bool get hasVegOptions =>
      tags.any(
        (t) =>
            t.toLowerCase().contains('veg'),
      );

  // ─────────────────────────────────────────────
  // Joining date
  // ─────────────────────────────────────────────
  String get joiningDateText {
    if (createdAt == null) {
      return 'Unavailable';
    }

    return DateFormat('MMM yyyy')
        .format(createdAt!);
  }

  // ─────────────────────────────────────────────
  // FSSAI display
  // ─────────────────────────────────────────────
  String get fssaiDisplay =>
      fssaiLicense.trim().isEmpty
          ? 'Not available'
          : fssaiLicense;

  // ─────────────────────────────────────────────
  // GST display (masked)
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // Order eligibility
  // ─────────────────────────────────────────────
  bool get canAcceptOrders =>
      isActive &&
      isAcceptingOrders &&
      isCurrentlyOpen;

  // ─────────────────────────────────────────────
  // Operating hours available
  // ─────────────────────────────────────────────
  bool get hasOperatingHours =>
      operatingHours.isNotEmpty;
}