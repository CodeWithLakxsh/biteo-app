// ============================================================
// lib/features/address/domain/entities/address_entity.dart
// Pure domain entity. No Firebase, no Flutter. Immutable.
// ============================================================

class AddressEntity {
  final String id;
  final String label;
  final String fullAddress;
  final String? flatHouseNo;
  final String? floor;
  final String? landmark;
  final String? buildingName;
  final double lat;
  final double lng;
  final String geohash;
  final bool isDefault;
  final String? contactName;
  final String? contactPhone;
  final DateTime? createdAt;

  const AddressEntity({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.flatHouseNo,
    this.floor,
    this.landmark,
    this.buildingName,
    required this.lat,
    required this.lng,
    required this.geohash,
    this.isDefault = false,
    this.contactName,
    this.contactPhone,
    this.createdAt,
  });

  // 🔥 ADD THIS (REQUIRED FIX)
  factory AddressEntity.fromMap(String id, Map<String, dynamic> map) {
    return AddressEntity(
      id: id,
      label: map['label'] ?? 'other',
      fullAddress: map['fullAddress'] ?? map['address'] ?? '',
      flatHouseNo: map['flatHouseNo'],
      floor: map['floor'],
      landmark: map['landmark'],
      buildingName: map['buildingName'],
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      geohash: map['geohash'] ?? '',
      isDefault: map['isDefault'] ?? false,
      contactName: map['contactName'],
      contactPhone: map['contactPhone'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  // 🔥 ALSO ADD THIS (useful for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'fullAddress': fullAddress,
      'flatHouseNo': flatHouseNo,
      'floor': floor,
      'landmark': landmark,
      'buildingName': buildingName,
      'lat': lat,
      'lng': lng,
      'geohash': geohash,
      'isDefault': isDefault,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get labelDisplay => switch (label) {
        'home' => 'Home',
        'work' => 'Work',
        _ => 'Other',
      };

  String get areaName {
    final parts = fullAddress.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return parts.isNotEmpty ? parts[0].trim() : fullAddress;
  }

  String get displayLine1 {
    final parts = <String>[
      if (flatHouseNo != null && flatHouseNo!.isNotEmpty) flatHouseNo!,
      if (buildingName != null && buildingName!.isNotEmpty) buildingName!,
    ];
    return parts.join(', ');
  }

  String get displayLine2 => fullAddress;

  AddressEntity copyWith({
    String? id,
    String? label,
    String? fullAddress,
    String? flatHouseNo,
    String? floor,
    String? landmark,
    String? buildingName,
    double? lat,
    double? lng,
    String? geohash,
    bool? isDefault,
    String? contactName,
    String? contactPhone,
    DateTime? createdAt,
  }) {
    return AddressEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      flatHouseNo: flatHouseNo ?? this.flatHouseNo,
      floor: floor ?? this.floor,
      landmark: landmark ?? this.landmark,
      buildingName: buildingName ?? this.buildingName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      geohash: geohash ?? this.geohash,
      isDefault: isDefault ?? this.isDefault,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}