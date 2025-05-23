import 'dart:convert';
import 'package:flutter/foundation.dart';

class Product {
  final String title;
  final String thumbnailPath;
  final String price;
  final dynamic category; // Can be String or Map<String, dynamic>
  final String? shortDescription;
  final String? fullDescription;
  final List<String>? images;
  final String? oldPrice;
  final String? discount;
  final String? id;
  final String? brand;
  final double? rating;
  final int? sold;
  final String? videoLink;
  final String? categoryId;
  final int? stockQuantity;
  final int? quantity; // Quantity selected by user for ordering

  const Product({
    required this.title,
    required this.thumbnailPath,
    required this.price,
    this.category,
    this.shortDescription,
    this.fullDescription,
    this.images,
    this.oldPrice,
    this.discount,
    this.id,
    this.brand,
    this.rating,
    this.sold,
    this.videoLink,
    this.categoryId,
    this.stockQuantity,
    this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Base URL for AWS S3 bucket
    const String awsBaseUrl =
        'https://pa-gebeya-upload.s3.eu-north-1.amazonaws.com/';

    // Helper function to get full image URLs
    List<String>? parseImages(dynamic imagesData) {
      if (imagesData == null) return null;
      try {
        if (imagesData is List) {
          return imagesData
              .where((e) => e != null)
              .map((e) => e.toString().startsWith('http')
                  ? e.toString()
                  : awsBaseUrl + e.toString())
              .where((url) => url.isNotEmpty)
              .toList();
        }
        return [awsBaseUrl + imagesData.toString()];
      } catch (e) {
        debugPrint("Error parsing images: $e");
        return null;
      }
    }

    // Get thumbnail URL - ensures we always have a valid URL
    String getThumbnail(dynamic imagesData) {
      try {
        if (imagesData is List && imagesData.isNotEmpty) {
          final firstImage = imagesData.first;
          return firstImage.toString().startsWith('http')
              ? firstImage.toString()
              : awsBaseUrl + firstImage.toString();
        }
        return awsBaseUrl +
            (json['image']?.toString() ?? 'default-product.jpg');
      } catch (e) {
        debugPrint("Error getting thumbnail: $e");
        return awsBaseUrl + 'default-product.jpg';
      }
    }

    // Handle category (either string or object)
    dynamic parseCategory(dynamic categoryData) {
      if (categoryData == null) return null;
      if (categoryData is Map) return categoryData;
      return categoryData.toString();
    }

    // Handle category ID (either from category object or separate field)
    String? parseCategoryId(dynamic categoryData) {
      if (categoryData == null) return null;
      if (categoryData is Map) return categoryData['_id']?.toString();
      if (json['categoryId'] != null) return json['categoryId'].toString();
      return null;
    }

    return Product(
      title: json['name']?.toString() ?? 'Unknown Product',
      thumbnailPath: getThumbnail(json['images']),
      price: (json['price']?.toString() ?? '0'),
      category: parseCategory(json['category']),
      shortDescription: json['shortDescription']?.toString(),
      fullDescription: json['fullDescription']?.toString(),
      images: parseImages(json['images']),
      oldPrice: json['hasDiscount'] == true
          ? (json['price']?.toString() ?? '0')
          : null,
      discount: json['discount']?.toString(),
      id: json['_id']?.toString(),
      brand: json['brand']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      sold: json['sold'] as int? ?? 0,
      videoLink: json['videoLink']?.toString(),
      categoryId: parseCategoryId(json['category']),
      stockQuantity: json['stockQuantity'] as int?,
      quantity: json['quantity'] as int? ?? 1, // Default quantity is 1
    );
  }

  Map<String, dynamic> toJson() => {
        'name': title,
        'image': thumbnailPath.split('/').last,
        'price': price,
        'category': category is Map ? category : {'name': category},
        'shortDescription': shortDescription,
        'fullDescription': fullDescription,
        'images': images?.map((url) => url.split('/').last).toList(),
        'originalPrice': oldPrice,
        'discount': discount,
        '_id': id,
        'brand': brand,
        'rating': rating,
        'sold': sold,
        'videoLink': videoLink,
        'categoryId': categoryId,
        'stockQuantity': stockQuantity,
        'quantity': quantity,
      };

  // Helper method to get category name regardless of type
  String? get categoryName {
    if (category == null) return null;
    if (category is Map) return category['name']?.toString();
    return category.toString();
  }

  // Helper method to get category ID regardless of type
  String? get effectiveCategoryId {
    if (categoryId != null) return categoryId;
    if (category is Map) return category['_id']?.toString();
    return null;
  }

  // Helper method to check if product is in stock
  bool get isInStock => (stockQuantity ?? 0) > 0;

  // Helper method to check if requested quantity is available
  bool isQuantityAvailable([int? requestedQuantity]) {
    final qty = requestedQuantity ?? quantity ?? 1;
    return isInStock && qty <= (stockQuantity ?? 0);
  }

  // Creates a copy of the product with updated values
  Product copyWith({
    String? title,
    String? thumbnailPath,
    String? price,
    dynamic category,
    String? shortDescription,
    String? fullDescription,
    List<String>? images,
    String? oldPrice,
    String? discount,
    String? id,
    String? brand,
    double? rating,
    int? sold,
    String? videoLink,
    String? categoryId,
    int? stockQuantity,
    int? quantity,
  }) {
    return Product(
      title: title ?? this.title,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      price: price ?? this.price,
      category: category ?? this.category,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      images: images ?? this.images,
      oldPrice: oldPrice ?? this.oldPrice,
      discount: discount ?? this.discount,
      id: id ?? this.id,
      brand: brand ?? this.brand,
      rating: rating ?? this.rating,
      sold: sold ?? this.sold,
      videoLink: videoLink ?? this.videoLink,
      categoryId: categoryId ?? this.categoryId,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    return 'Product{title: $title, id: $id, price: $price, stockQuantity: $stockQuantity, quantity: $quantity}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          stockQuantity == other.stockQuantity &&
          quantity == other.quantity;

  @override
  int get hashCode => id.hashCode ^ stockQuantity.hashCode ^ quantity.hashCode;
}
