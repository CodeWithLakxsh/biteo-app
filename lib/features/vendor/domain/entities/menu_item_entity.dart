class MenuItemEntity {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final String? imageUrl;
  final String category;

  /// All prices in PAISE (integer). Never floats.
  final int originalPricePaise;
  final int discountedPricePaise;
  final int discountPercent;
  final int availableQuantity;
  final int maxPerOrder;
  final bool isVeg;
  final bool isVegan;
  final List<String> allergens;
  final bool isAvailable;
  final DateTime? availableFrom;
  final DateTime? availableUntil;

  const MenuItemEntity({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.category,
    required this.originalPricePaise,
    required this.discountedPricePaise,
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

  // 🔥 FINAL FIRESTORE PARSER (STABLE)
  factory MenuItemEntity.fromFirestore(
    Map<String, dynamic> data,
    String id,
    String vendorId,
  ) {
    final int pricePaise = (data['price_paise'] ?? 0).toInt();

    return MenuItemEntity(
      id: id,
      vendorId: vendorId,

      name: data['name'] ?? "",
      description: data['description'],
      imageUrl: data['image_url'] ?? "",

      category: data['category'] ?? "General",

      // PRICE
      originalPricePaise: pricePaise,
      discountedPricePaise: pricePaise,
      discountPercent: 0,

      // STOCK
      availableQuantity: data['available_quantity'] ?? 10,

      // FLAGS
      isVeg: data['is_veg'] ?? true,
      isVegan: data['is_vegan'] ?? false,
      allergens: List<String>.from(data['allergens'] ?? []),

      isAvailable: data['is_available'] ?? true,

      availableFrom: null,
      availableUntil: null,
    );
  }

  // ── Computed Helpers ──────────────────────────────────────

  bool get isInStock => availableQuantity > 0 && isAvailable;

  String get originalPriceDisplay =>
      '₹${(originalPricePaise / 100).toStringAsFixed(0)}';

  String get discountedPriceDisplay =>
      '₹${(discountedPricePaise / 100).toStringAsFixed(0)}';

  String get discountBadge => '$discountPercent% off';

  int get savingsPaise => originalPricePaise - discountedPricePaise;

  String get savingsDisplay =>
      '₹${(savingsPaise / 100).toStringAsFixed(0)} saved';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemEntity &&
          id == other.id &&
          vendorId == other.vendorId;

  @override
  int get hashCode => id.hashCode ^ vendorId.hashCode;
}