import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:laza/components/product_card.dart';
import 'package:laza/models/index.dart';
import 'package:laza/extensions/context_extension.dart';

class BestsellerScreen extends StatefulWidget {
  const BestsellerScreen({super.key});

  @override
  _BestsellerScreenState createState() => _BestsellerScreenState();
}

class _BestsellerScreenState extends State<BestsellerScreen> {
  late Future<List<Product>> futureProducts;
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
      print("✅ User is logged in: userId=$userId");
    } else {
      setState(() {
        isLoggedIn = false;
        userId = null;
      });
      print("🚨 User is not logged in or token expired.");
    }
  }

  // Fetch products from the API
  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse(
        'https://pa-gebeya-backend.onrender.com/api/products/bestsellers'));

    print("🔹 API Response: ${response.body}"); // Debugging

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      // Debugging: Print product data before parsing
      print("🟢 Raw Product Data: ${data}");

      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<void> storeUserDetails(String userId, String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('token', token);

    print("✅ Stored userId: $userId and token: $token");

    // Verify immediately after storing
    String? storedUserId = prefs.getString('userId');
    print("🔍 Stored userId after verification: $storedUserId");
  }

  // Retrieve userId from SharedPreferences
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    print("Retrieved userId from SharedPreferences: $userId"); // Debug log
    return userId;
  }

  // Retrieve token from SharedPreferences
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    print("🔑 Retrieved token from SharedPreferences: $token");
    return token;
  }

  Future<void> addToCart(Product product) async {
    await checkLoginStatus(); // Ensure we update login state before proceeding

    if (!isLoggedIn || userId == null) {
      showToast("Please login to add items to the cart", error: true);
      return;
    }

    // Directly access the token from user data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      showToast("Token is missing or expired. Please log in again.",
          error: true);
      return;
    }

    // Ensure product ID is valid
    if (product.id == null || product.id!.isEmpty) {
      print("🚨 Error: Product ID is null or empty!");
      showToast("Error: Product ID is missing", error: true);
      return;
    }

    final url = Uri.parse('https://pa-gebeya-backend.onrender.com/api/cart');

    final Map<String, dynamic> requestBody = {
      "userId": userId,
      "items": [
        {
          "productId": product.id,
          "productName": product.title,
          "img": product.thumbnailPath ?? "",
          "price": product.price,
          "quantity": cartItems[product.id] ?? 1,
        }
      ]
    };

    print("🔹 Sending request to: $url");
    print("📌 Request body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print("✅ Response Status: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        showToast(
            "${cartItems[product.id] ?? 1} ${product.title} added to cart");
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? "Unknown error";
        showToast("Failed to add ${product.title} to cart: $errorMessage",
            error: true);
      }
    } catch (error) {
      print("❌ Error adding to cart: $error");
      showToast("Error adding to cart. Please try again.", error: true);
    }
  }

  // Update product quantity
  void updateQuantity(String? productId, bool increase) {
    if (productId == null) return;

    setState(() {
      int currentQuantity = cartItems[productId] ?? 0;
      if (increase) {
        cartItems[productId] = currentQuantity + 1;
        print(
            "Increased quantity of product $productId to ${cartItems[productId]}");
      } else {
        cartItems[productId] = (currentQuantity > 1) ? currentQuantity - 1 : 0;
        print(
            "Decreased quantity of product $productId to ${cartItems[productId]}");
      }

      if (cartItems[productId]! <= 0) {
        cartItems.remove(productId);
        print("Removed product $productId from the cart");
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Headline(
          headline: 'Best Sellers',
          onViewAllTap: () {},
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
                return const Center(child: Text('No products available'));
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.thumbnailPath,
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported,
                                          size: 100),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                product.title,
                                style: context.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '\$${product.price}',
                                style: context.bodyLargeW500?.copyWith(
                                  color: Colors.blue,
                                ),
                              ),
                              const Spacer(),
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
                                          onPressed: () {
                                            print(
                                                "Decreasing quantity for ${product.id}");
                                            updateQuantity(product.id, false);
                                          },
                                        ),
                                        Text(
                                          "${cartItems[product.id] ?? 0}",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add,
                                              color: Colors.green),
                                          onPressed: () {
                                            print(
                                                "Increasing quantity for ${product.id}");
                                            updateQuantity(product.id, true);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      print(
                                          "Adding product ${product.id} to the cart");
                                      addToCart(product);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.shopping_cart,
                                          color: Colors.white),
                                    ),
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          TextButton(
            onPressed: onViewAllTap,
            child: Text(
              'View All',
              style: context.bodyLargeW500?.copyWith(
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
