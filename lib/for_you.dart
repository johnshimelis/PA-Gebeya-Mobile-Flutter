import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:laza/models/index.dart';
import 'package:laza/extensions/context_extension.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  _ForYouScreenState createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  late Future<List<ProductDetail>> futureProducts;
  List<ProductDetail> allProducts = [];
  List<ProductDetail> displayedProducts = [];
  int itemsToShow = 10; // Show 10 products initially

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
  }

  Future<List<ProductDetail>> fetchProducts() async {
    final response = await http.get(
      Uri.parse('https://pa-gebeya-backend.onrender.com/api/products/'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      List<ProductDetail> products = data
          .map((item) => ProductDetail.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        allProducts = products;
        displayedProducts = allProducts.take(itemsToShow).toList();
      });

      return products;
    } else {
      throw Exception('Failed to load products');
    }
  }

  void _loadMoreProducts() {
    setState(() {
      int nextCount = displayedProducts.length + 10;
      displayedProducts = allProducts.take(nextCount).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductDetail>>(
      future: futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No products available'));
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Headline(
                headline: 'For You',
                onViewAllTap: () {},
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two products per row
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 0.67, // Adjusted for better display
                  ),
                  itemBuilder: (context, index) {
                    return _buildProductCard(displayedProducts[index]);
                  },
                ),
              ),
              if (displayedProducts.length < allProducts.length)
                Center(
                  child: TextButton(
                    onPressed: _loadMoreProducts,
                    child:
                        const Text('See More', style: TextStyle(fontSize: 16)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductDetail product) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.photo,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 100),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              '\$${product.price}',
              style: TextStyle(fontSize: 14, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.red),
                        onPressed: () {},
                      ),
                      const Text("0"),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
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
                  child: const Icon(Icons.shopping_cart, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: onViewAllTap,
            child: Text('View All', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}
