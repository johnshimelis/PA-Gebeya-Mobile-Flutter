class Product {
  final String id;
  final String name; // Add this field
  final String category;
  final double price;
  final int discount;
  final bool hasDiscount;
  final String image; // Add this field

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.discount,
    required this.hasDiscount,
    required this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      category: json['category'],
      price: json['price'].toDouble(),
      discount: json['discount'],
      hasDiscount: json['hasDiscount'],
      image: json['image'],
    );
  }
}
