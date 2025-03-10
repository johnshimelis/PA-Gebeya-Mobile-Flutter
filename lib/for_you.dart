import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:laza/models/index.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/product_details.dart'; // Import the product details screen

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
  Map<String, int> cartItems = {}; // Track product quantities in the cart
  bool isLoggedIn = false;
  String? userId; // Store userId here to track the user's state

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
    checkLoginStatus(); // Make sure we check login status at the start
  }

  bool isTokenExpired(String? token) {
    if (token == null) return true;

    try {
      final parts = token.split(".");
      if (parts.length != 3) {
        throw Exception("Invalid JWT structure");
      }

      String payload = parts[1];
      // Normalize Base64 string (add padding)
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decodedPayload = utf8.decode(base64Url.decode(payload));
      final payloadMap = json.decode(decodedPayload);
      final exp = payloadMap["exp"] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return now >= exp;
    } catch (e) {
      debugPrint("❌ Error decoding token: $e");
      return true; // Assume expired if there's an error
    }
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedToken = prefs.getString('token');
    userId = prefs.getString('userId');

    if (storedToken != null &&
        storedToken.isNotEmpty &&
        !isTokenExpired(storedToken)) {
      setState(() {
        isLoggedIn = true;
      });
      debugPrint("✅ User is logged in: userId=$userId");
    } else {
      setState(() {
        isLoggedIn = false;
        userId = null;
      });
      debugPrint("🚨 User is not logged in or token expired.");
    }
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

  Future<void> addToCart(ProductDetail product) async {
    debugPrint("🟢 addToCart called for product: ${product.id}");

    // Ensure product ID is valid
    if (product.id == null || product.id!.isEmpty) {
      debugPrint("🚨 Error: Product ID is null or empty!");
      showToast("Error: Product ID is missing", error: true);
      return;
    }

    // Directly access the token from user data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? storedUserId = prefs.getString('userId');

    if (token == null || token.isEmpty) {
      debugPrint("🚨 Error: Token is missing or expired!");
      showToast("Token is missing or expired. Please log in again.",
          error: true);
      return;
    }

    if (storedUserId == null || storedUserId.isEmpty) {
      debugPrint("🚨 Error: User ID is missing!");
      showToast("User ID is missing. Please log in again.", error: true);
      return;
    }

    final url = Uri.parse('https://pa-gebeya-backend.onrender.com/api/cart');

    // Create a multipart request
    var request = http.MultipartRequest('POST', url);

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add fields to the request
    request.fields['userId'] =
        storedUserId; // Use storedUserId instead of userId
    request.fields['productId'] = product.id!;
    request.fields['productName'] = product.name;
    request.fields['price'] =
        product.price.toString(); // Convert double to String
    request.fields['quantity'] = (cartItems[product.id] ?? 1).toString();

    // Add image URL as a field
    if (product.photo != null && product.photo!.isNotEmpty) {
      request.fields['img'] = product.photo!; // Use 'img' as the field name
      debugPrint("🟢 Image URL added to request: ${product.photo}");
    }

    debugPrint("🔹 Sending request to: $url");
    debugPrint("📌 Request fields: ${request.fields}");

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint("✅ Response Status: ${response.statusCode}");
      debugPrint("📩 Response Body: $responseBody");

      if (response.statusCode == 200) {
        showToast(
            "${cartItems[product.id] ?? 1} ${product.name} added to cart");
      } else {
        final errorMessage =
            jsonDecode(responseBody)['error'] ?? "Unknown error";
        showToast("Please login first to add ${product.name} to cart",
            error: true);
      }
    } catch (error) {
      debugPrint("❌ Error adding to cart: $error");
      showToast("Error adding to cart. Please try again.", error: true);
    }
  }

  // Update product quantity
  void updateQuantity(String? productId, bool increase) {
    if (productId == null) {
      debugPrint("🚨 Error: Product ID is null!");
      showToast("Error: Product ID is missing", error: true);
      return;
    }

    setState(() {
      int currentQuantity = cartItems[productId] ?? 0;
      if (increase) {
        cartItems[productId] = currentQuantity + 1;
        debugPrint(
            "Increased quantity of product $productId to ${cartItems[productId]}");
      } else {
        cartItems[productId] = (currentQuantity > 1) ? currentQuantity - 1 : 0;
        debugPrint(
            "Decreased quantity of product $productId to ${cartItems[productId]}");
      }

      if (cartItems[productId]! <= 0) {
        cartItems.remove(productId);
        debugPrint("Removed product $productId from the cart");
      }
    });
  }

  // Show toast messages
  void showToast(String message, {bool error = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: error ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
      timeInSecForIosWeb: 3,
    );
  }

  void _loadMoreProducts() {
    setState(() {
      int nextCount = displayedProducts.length + 10;
      displayedProducts = allProducts.take(nextCount).toList();
    });
  }

  // Convert ProductDetail to Product
  Product convertToProduct(ProductDetail productDetail) {
    return Product(
      id: productDetail.id,
      title: productDetail
          .name, // Assuming 'name' in ProductDetail maps to 'title' in Product
      price: productDetail.price.toString(), // Convert to String if needed
      thumbnailPath: productDetail.photo,

      // Add other fields as needed
    );
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
    return GestureDetector(
      onTap: () {
        // Convert ProductDetail to Product
        Product convertedProduct = convertToProduct(product);
        // Navigate to the product details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailsScreen(product: convertedProduct),
          ),
        );
      },
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
                          onPressed: () {
                            updateQuantity(product.id, false);
                          },
                        ),
                        Text(
                          "${cartItems[product.id] ?? 0}",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () {
                            updateQuantity(product.id, true);
                          },
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      addToCart(product);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          const Icon(Icons.shopping_cart, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
