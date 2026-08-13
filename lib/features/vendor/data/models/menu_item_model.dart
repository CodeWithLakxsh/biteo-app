import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/menu_item_entity.dart';

class MenuItemModel {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final String? imageUrl;
  final String category;
  final int originalPrice;
  final int discountedPrice;
  final int discountPercent;
  final int availableQuantity;
  final int maxPerOrder;
  final bool isVeg;
  final bool isVegan;
  final List<String> allergens;
  final bool isAvailable;
  final DateTime? availableFrom;
  final DateTime? availableUntil;

  const MenuItemModel({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercent,
    required this.availableQuantity,
    this.maxPerOrder = 5,
    this.isVeg = true,
    this.isVegan = false,
    this.allergens = const [],
    this.isAvailable = true,
    this.availableFrom,
    this.availableUntil,
  });

  // 🔥 FINAL PARSER WITH DISCOUNT LOGIC
  factory MenuItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String vendorId,
  ) {
    final d = doc.data() ?? {};

    // 🔥 BASE PRICE FROM VENDOR
    final int pricePaise = (d['price_paise'] ?? 0).toInt();

    // 🔥 APPLY 30% MARKUP FOR FAKE DISCOUNT
    final int originalPrice = (pricePaise * 1.3).round();

    return MenuItemModel(
      id: doc.id,
      vendorId: vendorId,

      // BASIC INFO
      name: d['name'] ?? '',
      description: d['description'],
      imageUrl: d['image_url'],
      category: d['category'] ?? 'General',

      // 🔥 PRICE SYSTEM
      originalPrice: originalPrice,        // ❌ Cut price (130)
      discountedPrice: pricePaise,         // ✅ Real price (100)
      discountPercent: 30,                 // 🔥 Always 30%

      // STOCK
      availableQuantity: (d['available_quantity'] ?? 10) as int,
      maxPerOrder: 5,

      // 🔥 VEG/NON-VEG FIX
      isVeg: d['is_veg'] == true,
      isVegan: d['is_vegan'] == true,

      allergens: List<String>.from(d['allergens'] ?? []),

      // AVAILABILITY
      isAvailable: d['is_available'] ?? true,

      availableFrom: null,
      availableUntil: null,
    );
  }

  // ── Convert to Entity ─────────────────────────────
  MenuItemEntity toEntity() => MenuItemEntity(
        id: id,
        vendorId: vendorId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        category: category,
        originalPricePaise: originalPrice,
        discountedPricePaise: discountedPrice,
        discountPercent: discountPercent,
        availableQuantity: availableQuantity,
        maxPerOrder: maxPerOrder,
        isVeg: isVeg,
        isVegan: isVegan,
        allergens: allergens,
        isAvailable: isAvailable,
        availableFrom: availableFrom,
        availableUntil: availableUntil,
      );
}