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
  final String? thumbnailPath;
  final Map<String, dynamic>?
      category; // Updated to handle category as an object
  final List<String>? images; // Added field
  final String? oldPrice; // Added field
  final String? brand; // Added field
  final double? rating; // Added field
  final int? sold; // Added field
  final String? videoLink; // Added field

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
    required this.thumbnailPath,
    this.category,
    this.images,
    this.oldPrice,
    this.brand,
    this.rating,
    this.sold,
    this.videoLink,
  });

  // From JSON response
  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    // Helper function to handle the category field
    Map<String, dynamic>? parseCategory(dynamic category) {
      if (category is Map<String, dynamic>) {
        return category;
      }
      return null; // Return null if the category is not a Map
    }

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
      thumbnailPath: json['thumbnailPath'],
      category: parseCategory(json['category']), // Handle category as a Map
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(), // Handle images as a list
      oldPrice: json['originalPrice']?.toString() ??
          json['price'].toString(), // Handle oldPrice
      brand: json['brand'], // Handle brand
      rating: (json['rating'] as num?)?.toDouble(), // Handle rating
      sold: json['sold'] as int?, // Handle sold
      videoLink: json['videoLink'] as String?, // Handle videoLink
    );
  }
}
