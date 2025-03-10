import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laza/components/bottom_nav_button.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/components/custom_appbar.dart';
import 'package:laza/components/laza_icons.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/order_confirmed_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:laza/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  String? userId;
  double totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    String? token = prefs.getString('token');

    if (userId == null || token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
        'https://pa-gebeya-backend.onrender.com/api/cart?userId=$userId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          cartItems = data['items'];
          totalAmount = calculateTotalAmount(cartItems);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        debugPrint("Failed to fetch cart items: ${response.statusCode}");
        debugPrint("Response Body: ${response.body}");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error fetching cart items: $error");
    }
  }

  double calculateTotalAmount(List<dynamic> items) {
    double total = 0.0;
    for (var item in items) {
      total += (item['price'] * item['quantity']);
    }
    return total;
  }

  Future<void> updateQuantity(String productId, bool increase) async {
    debugPrint(
        "🔄 updateQuantity called with productId: $productId, increase: $increase");

    if (productId.isEmpty) {
      debugPrint("🚨 Error: Product ID is empty!");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    if (token == null || userId == null) {
      debugPrint("🚨 Error: Missing authentication token or userId!");
      return;
    }

    // Find the item in the cart
    final itemIndex = cartItems.indexWhere((item) {
      // Handle nested productId structure
      final itemProductId = item['productId'] is String
          ? item['productId'] // If productId is a string
          : item['productId']['_id']; // If productId is an object
      return itemProductId == productId;
    });

    if (itemIndex == -1) {
      debugPrint("🚨 Error: Product not found in cart!");
      return;
    }

    debugPrint("✅ Found item in cart at index: $itemIndex");

    // Get current quantity & calculate new quantity
    int currentQuantity = cartItems[itemIndex]['quantity'];
    int newQuantity = increase ? currentQuantity + 1 : currentQuantity - 1;

    debugPrint(
        "🔢 Current quantity: $currentQuantity, New quantity: $newQuantity");

    // Prevent negative quantity
    if (newQuantity <= 0) {
      debugPrint("🚨 Error: Quantity cannot be less than 1!");
      return;
    }

    // API URL for updating quantity
    final url =
        Uri.parse('https://pa-gebeya-backend.onrender.com/api/cart/$productId');

    try {
      debugPrint("📤 Sending PUT request to: $url");
      debugPrint("🔹 Headers: Authorization: Bearer $token");
      debugPrint("🔹 Request Body: ${jsonEncode({
            'userId': userId,
            'productId': productId, // Include productId in the request body
            'quantity': newQuantity,
          })}");

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'productId': productId, // Include productId in the request body
          'quantity': newQuantity,
        }),
      );

      debugPrint("📥 Response Status Code: ${response.statusCode}");
      debugPrint("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Update the UI immediately
        if (mounted) {
          setState(() {
            cartItems[itemIndex]['quantity'] = newQuantity;
            totalAmount = calculateTotalAmount(cartItems);
          });
        }

        debugPrint("✅ Quantity updated to $newQuantity in the UI");

        // Show toast for successful update
        Fluttertoast.showToast(
          msg: "✅ Quantity updated to $newQuantity",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        debugPrint("❌ Failed to update quantity: ${response.statusCode}");
        debugPrint("❌ Response Body: ${response.body}");
      }
    } catch (error) {
      debugPrint("🚨 Error updating quantity: $error");
    }
  }

  Future<void> removeItem(String productId) async {
    debugPrint("🔄 removeItem called with productId: $productId");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    if (token == null || userId == null) {
      debugPrint("🚨 Error: Missing authentication token or userId!");
      return;
    }

    // Sync the removal with the backend
    final url =
        Uri.parse('https://pa-gebeya-backend.onrender.com/api/cart/$productId');
    try {
      debugPrint("📤 Sending DELETE request to: $url");
      debugPrint("🔹 Headers: Authorization: Bearer $token");
      debugPrint("🔹 Request Body: ${jsonEncode({
            'userId': userId,
          })}");

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId, // Include userId in the request body
        }),
      );

      debugPrint("📥 Response Status Code: ${response.statusCode}");
      debugPrint("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Remove the item locally after successful backend removal
        if (mounted) {
          setState(() {
            cartItems.removeWhere((item) {
              // Handle nested productId structure
              final itemProductId = item['productId'] is String
                  ? item['productId'] // If productId is a string
                  : item['productId']['_id']; // If productId is an object
              return itemProductId == productId;
            });
            totalAmount = calculateTotalAmount(cartItems);
          });
        }

        debugPrint("✅ Item removed from the UI");

        // Fetch updated cart data from the backend
        await fetchCartItems();

        Fluttertoast.showToast(
          msg: "Item removed successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Failed to remove item. Please try again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        debugPrint("❌ Failed to remove item: ${response.statusCode}");
        debugPrint("❌ Response Body: ${response.body}");
      }
    } catch (error) {
      Fluttertoast.showToast(
        msg: "Error removing item. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      debugPrint("🚨 Error removing item: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Cart'),
        bottomNavigationBar: BottomNavButton(
          label: 'Checkout',
          onTap: () async {
            // Store cart items and total amount in SharedPreferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString(
                'cartItems', jsonEncode(cartItems)); // Store cart items as JSON
            prefs.setDouble('totalAmount', totalAmount); // Store total amount

            // Navigate to the CheckoutScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
            );
          },
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 25.0),
                children: [
                  if (cartItems.isEmpty)
                    const Center(child: Text('Your cart is empty'))
                  else
                    ...cartItems.map((item) {
                      debugPrint(
                          "Item: ${item.toString()}"); // Log the entire item
                      final imageUrl = item['img'];
                      debugPrint("Image URL: $imageUrl");

                      return Container(
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 20.0),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: context.theme.cardColor,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10.0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: context.theme.scaffoldBackgroundColor,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10.0)),
                                image: imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(imageUrl),
                                        fit: BoxFit.cover,
                                        onError: (exception, stackTrace) {
                                          debugPrint(
                                              "Failed to load image: $exception");
                                        },
                                      )
                                    : null,
                              ),
                              child: imageUrl == null
                                  ? const Icon(Icons.image_not_supported,
                                      size: 50)
                                  : null,
                            ),
                            const SizedBox(width: 10.0),
                            Flexible(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['productName'] ?? 'No Name',
                                        style: context.bodySmallW500,
                                      ),
                                      const SizedBox(height: 10.0),
                                      Text(
                                        "\$${item['price']} (-\$4.00 Tax)",
                                        style: context.bodyExtraSmall?.copyWith(
                                            color: ColorConstant.manatee),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(50)),
                                              onTap: () {
                                                final productId = item[
                                                        'productId'] is String
                                                    ? item['productId']
                                                    : item['productId'][
                                                        '_id']; // Handle both cases
                                                updateQuantity(
                                                    productId, false);
                                              },
                                              child: Ink(
                                                width: 30,
                                                height: 30,
                                                decoration: ShapeDecoration(
                                                  color: context.theme
                                                      .scaffoldBackgroundColor,
                                                  shape: const CircleBorder(),
                                                ),
                                                child: const Icon(
                                                    Icons.arrow_drop_down),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 15.0),
                                          Text('${item['quantity']}'),
                                          const SizedBox(width: 15.0),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(50)),
                                              onTap: () {
                                                final productId = item[
                                                        'productId'] is String
                                                    ? item['productId']
                                                    : item['productId'][
                                                        '_id']; // Handle both cases
                                                updateQuantity(productId, true);
                                              },
                                              child: Ink(
                                                width: 30,
                                                height: 30,
                                                decoration: ShapeDecoration(
                                                  color: context.theme
                                                      .scaffoldBackgroundColor,
                                                  shape: const CircleBorder(),
                                                ),
                                                child: const Icon(
                                                    Icons.arrow_drop_up),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(50)),
                                          onTap: () {
                                            final productId = item['productId']
                                                    is String
                                                ? item['productId']
                                                : item['productId'][
                                                    '_id']; // Handle both cases
                                            removeItem(productId);
                                          },
                                          child: Ink(
                                            width: 30,
                                            height: 30,
                                            decoration: ShapeDecoration(
                                              color: context.theme
                                                  .scaffoldBackgroundColor,
                                              shape: const CircleBorder(),
                                            ),
                                            child: const Icon(Icons.delete,
                                                size: 14.0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                  // Add Order Info Section Here
                  if (cartItems.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20.0), // Add some spacing
                        Text(
                          'Order Info',
                          style: context.bodyLargeW500,
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal',
                                style: context.bodyMedium
                                    ?.copyWith(color: ColorConstant.manatee)),
                            Text('\$${totalAmount.toStringAsFixed(2)}',
                                style: context.bodyMediumW500),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Shipping cost',
                                style: context.bodyMedium
                                    ?.copyWith(color: ColorConstant.manatee)),
                            Text('\$0.00', style: context.bodyMediumW500),
                          ],
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: context.bodyMedium
                                    ?.copyWith(color: ColorConstant.manatee)),
                            Text('\$${totalAmount.toStringAsFixed(2)}',
                                style: context.bodyMediumW500),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}
