class Product {
  final String title;
  final String thumbnailPath;
  final String price;
  final String? category;
  final String? description;
  final List<String>? images;
  final String? oldPrice;
  final String? discount;
  final String? id; // New field: Unique Product ID
  final String? brand; // New field: Brand name
  final double? rating; // New field: Rating score

  const Product({
    required this.title,
    required this.thumbnailPath,
    required this.price,
    this.category,
    this.images,
    this.description,
    this.oldPrice,
    this.discount,
    this.id,
    this.brand,
    this.rating,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      title: json['name'] ?? 'Unknown Product',
      thumbnailPath: json['image'] ?? '',
      price: json['calculatedPrice']?.toString() ?? json['price'].toString(),
      category: json['category'],
      description: json['description'],
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      oldPrice: json['originalPrice']?.toString() ?? json['price'].toString(),
      discount: json['discount']?.toString(),
      id: json['_id']?.toString() ??
          json['id']?.toString(), // Ensure ID is retrieved correctly
      brand: json['brand'],
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  // Convert Product instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': title,
      'image': thumbnailPath,
      'calculatedPrice': price,
      'category': category,
      'description': description,
      'images': images,
      'originalPrice': oldPrice,
      'discount': discount,
      'id': id,
      'brand': brand,
      'rating': rating,
    };
  }
}
