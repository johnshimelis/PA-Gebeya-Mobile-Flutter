class ProductDetail {
  final String id;
  final String name;
  final double price;
  final String shortDescription;
  final String fullDescription;
  final int stockQuantity;
  final String photo;
  final bool hasDiscount;
  final double discount;

  ProductDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.shortDescription,
    required this.fullDescription,
    required this.stockQuantity,
    required this.photo,
    required this.hasDiscount,
    required this.discount,
  });

  // From JSON response
  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      shortDescription: json['shortDescription'] ?? '',
      fullDescription: json['fullDescription'] ?? '',
      stockQuantity: json['stockQuantity'] ?? 0,
      photo: json['photo'] ?? '',
      hasDiscount: json['hasDiscount'] ?? false,
      discount: json['discount']?.toDouble() ?? 0.0,
    );
  }
}
