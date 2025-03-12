import 'package:flutter/material.dart';
import 'package:laza/components/bottom_nav_button.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/models/index.dart';
import 'package:laza/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late String selectedImage;
  int quantity = 1; // Track quantity in the product details screen

  @override
  void initState() {
    selectedImage = widget.product.thumbnailPath;
    super.initState();
  }

  Future<void> addToCart(Product product) async {
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
    String? userId = prefs.getString('userId'); // Ensure userId is not null

    if (token == null || token.isEmpty) {
      debugPrint("🚨 Error: Token is missing or expired!");
      showToast("Please login to add items to the cart", error: true);
      return;
    }

    if (userId == null || userId.isEmpty) {
      debugPrint("🚨 Error: User ID is missing!");
      showToast("Please login to add items to the cart", error: true);
      return;
    }

    final url = Uri.parse('https://pa-gebeya-backend.onrender.com/api/cart');

    // Create a multipart request
    var request = http.MultipartRequest('POST', url);

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add fields to the request
    request.fields['userId'] = userId;
    request.fields['productId'] = product.id!;
    request.fields['productName'] = product.title;
    request.fields['price'] = product.price.toString();
    request.fields['quantity'] =
        quantity.toString(); // Use the quantity from the state

    // Add image URL as a field (if available)
    if (product.thumbnailPath != null && product.thumbnailPath!.isNotEmpty) {
      request.fields['img'] =
          product.thumbnailPath!; // Send the image URL directly
      debugPrint("🟢 Image URL added to request: ${product.thumbnailPath}");
    } else {
      debugPrint("🚨 Warning: Product image is missing!");
    }

    // Log all fields being added to the request
    debugPrint("📌 Request Fields:");
    request.fields.forEach((key, value) {
      debugPrint("$key: $value");
    });

    debugPrint("🔹 Sending request to: $url");

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint("✅ Response Status: ${response.statusCode}");
      debugPrint("📩 Response Body: $responseBody");

      if (response.statusCode == 200) {
        showToast("$quantity ${product.title} added to cart");
      } else {
        final errorMessage =
            jsonDecode(responseBody)['error'] ?? "Unknown error";
        showToast("Failed to add ${product.title} to cart: $errorMessage",
            error: true);
      }
    } catch (error) {
      debugPrint("❌ Error adding to cart: $error");
      showToast("Error adding to cart. Please try again.", error: true);
    }
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
    final product = widget.product;
    final bottomPadding =
        context.bottomViewPadding == 0.0 ? 30.0 : context.bottomViewPadding;
    return Scaffold(
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 0),
          Container(
            color: context.theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Price', style: context.bodyMediumW600),
                    Text('with VAT,SD',
                        style: context.bodyExtraSmall
                            ?.copyWith(color: ColorConstant.manatee)),
                  ],
                ),
                Text(
                    '\$${(double.parse(product.price) * quantity).toStringAsFixed(2)}',
                    style: context.bodyLargeW600)
              ],
            ),
          ),
          BottomNavButton(
            label: 'Add to Cart',
            onTap: () => addToCart(
                widget.product), // Call addToCart when the button is pressed
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            title: InkWell(
              borderRadius: BorderRadius.circular(56),
              radius: 56,
              onTap: () => Navigator.pop(context),
              child: Ink(
                width: 45,
                height: 45,
                decoration: ShapeDecoration(
                  color: AppTheme.lightTheme.cardColor,
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.arrow_back_outlined),
              ),
            ),
            centerTitle: false,
            pinned: true,
            actions: [
              InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(50)),
                onTap: () {},
                child: Ink(
                  width: 45,
                  height: 45,
                  decoration: ShapeDecoration(
                    color: AppTheme.lightTheme.cardColor,
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons
                      .favorite_border), // Replaced LazaIcons.heart with Icons.favorite_border
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20.0, left: 10.0),
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(
                        onCartUpdated: () {
                          // Callback to refresh cart count
                          // You can implement this logic in the parent widget
                        },
                      ),
                    ),
                  ),
                  child: Ink(
                    width: 45,
                    height: 45,
                    decoration: ShapeDecoration(
                      color: AppTheme.lightTheme.cardColor,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(
                      Icons
                          .shopping_cart, // Replaced LazaIcons.bag with Icons.shopping_cart
                    ),
                  ),
                ),
              ),
            ],
            backgroundColor: const Color(0xffF2F2F2),
            surfaceTintColor: Colors.transparent,
            expandedHeight: 400,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                  child: Image.network(
                selectedImage,
                fit: BoxFit.fitHeight,
              )),
            ),
            systemOverlayStyle:
                context.theme.appBarTheme.systemOverlayStyle!.copyWith(
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.category ?? 'Men\'s Printed Pullover Hoodie',
                          style: context.bodySmall),
                      const SizedBox(height: 5.0),
                      Text(
                        product.title,
                        style: context.headlineSmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price', style: context.bodySmall),
                    const SizedBox(height: 5.0),
                    Text(
                      product.price,
                      style: context.headlineSmall,
                    ),
                  ],
                ),
              ],
            ),
          )),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          if (widget.product.images != null)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                width: double.infinity,
                child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final image = widget.product.images![index];
                      return InkWell(
                        onTap: () => setState(() => selectedImage = image),
                        child: Ink(
                          height: double.infinity,
                          width: 80,
                          decoration: BoxDecoration(
                            image: DecorationImage(image: AssetImage(image)),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10.0),
                    itemCount: widget.product.images!.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 5)),
          // ============================================================
          // Size Guide
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Size',
                        style: context.bodyLargeW600,
                      ),
                      TextButton(
                          onPressed: () {},
                          child: Text('Size Guide',
                              style: context.bodyMedium?.copyWith(
                                  color: context.theme.primaryColor))),
                    ],
                  ),
                ),
                SizedBox(
                  height: 70,
                  width: double.infinity,
                  child: ListView.separated(
                      separatorBuilder: (_, __) => const SizedBox(width: 10.0),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final text = ['S', 'M', 'L', 'XL', 'XXL'][index];
                        return Container(
                          height: 70,
                          width: 70,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.theme.cardColor,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10.0)),
                          ),
                          child: Text(
                            text,
                            style: context.bodyLargeW600,
                          ),
                        );
                      }),
                )
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // ============================================================
          // Quantity Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantity',
                    style: context.bodyLargeW600,
                  ),
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
                            setState(() {
                              if (quantity > 1) {
                                quantity--;
                              }
                            });
                          },
                        ),
                        Text(
                          "$quantity",
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
                            setState(() {
                              quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // ============================================================
          // Description
          if (product.description != null)
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: context.bodyLargeW600),
                  const SizedBox(height: 10.0),
                  Text(product.description!,
                      style: context.bodyMedium
                          ?.copyWith(color: ColorConstant.manatee)),
                  const SizedBox(height: 20.0),
                ],
              ),
            )),
          // ============================================================
          // Bottom padding
          SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
        ],
      ),
    );
  }
}
