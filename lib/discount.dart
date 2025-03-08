import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:laza/components/product_card.dart';
import 'package:laza/models/index.dart';
import 'package:laza/extensions/context_extension.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});

  @override
  _DiscountScreenState createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  late Future<List<Product>> futureProducts;

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
  }

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse(
        'https://pa-gebeya-backend.onrender.com/api/products/discounted'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      // Log the response data to verify oldPrice
      print('Fetched Products: $data');

      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load discounted products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Headline(
          headline: 'Discounts',
        ),
        SizedBox(
          height: 270,
          child: FutureBuilder<List<Product>>(
            future: futureProducts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No discounted products available'));
              }

              final products = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 10.0),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: SizedBox(
                      width: 180,
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product.thumbnailPath,
                                      height: 100,
                                      width: double
                                          .infinity, // Make image fit the card width
                                      fit: BoxFit
                                          .cover, // Ensure the image covers the area without cropping
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          const Icon(Icons.image_not_supported,
                                              size: 100),
                                    ),
                                  ),
                                  if (product.discount != null)
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${product.discount}% off', // Show discount as percentage
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(), // Pushes content to the bottom
                              Text(
                                product.title,
                                style: context.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                                maxLines: 1, // Ensure name is in one line
                                overflow: TextOverflow
                                    .ellipsis, // Add ellipsis if overflow
                              ),
                              const SizedBox(
                                  height: 5), // Gap between name and price
                              Row(
                                children: [
                                  Text(
                                    '\$${product.price}', // Current price (calculatedPrice)
                                    style: context.bodyLargeW500?.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                          20), // Adjust the width to your desired gap
                                  if (product.oldPrice != null &&
                                      product.oldPrice!.isNotEmpty)
                                    Text(
                                      '\$${product.oldPrice}', // Old price (originalPrice or price)
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors
                                            .red, // Red color for the original price
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 10), // Additional spacing
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove,
                                              color: Colors.red),
                                          onPressed: () {},
                                        ),
                                        const Text(
                                          "0",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add,
                                              color: Colors.green),
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.shopping_cart,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class Headline extends StatelessWidget {
  const Headline({super.key, required this.headline, this.onViewAllTap});
  final String headline;
  final void Function()? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            headline,
            style: context.bodyLargeW500?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onViewAllTap,
            child: Text(
              'View All',
              style: context.bodySmall?.copyWith(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }
}
