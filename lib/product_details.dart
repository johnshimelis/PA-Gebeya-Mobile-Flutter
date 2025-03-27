import 'package:flutter/material.dart';
import 'package:laza/components/bottom_nav_button.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/models/index.dart';
import 'package:laza/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  late String selectedImage;
  int quantity = 1;
  List<Product> relatedProducts = [];
  bool isLoadingRelated = false;
  late AnimationController _animationController;
  final Map<String, PageController> _pageControllers = {};
  final Map<String, Timer> _timers = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    selectedImage =
        widget.product.images?.first ?? widget.product.thumbnailPath ?? '';
    fetchRelatedProducts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _pageControllers.values) {
      controller.dispose();
    }
    for (var timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _startAutoScroll(String productId, int imageCount) {
    _timers[productId] = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageControllers[productId]!.hasClients) {
        if (_pageControllers[productId]!.page ==
            (_pageControllers[productId]!.position.maxScrollExtent / 200)
                .floor()) {
          _pageControllers[productId]!.animateToPage(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _pageControllers[productId]!.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> fetchRelatedProducts() async {
    String? categoryId;
    if (widget.product.category is Map<String, dynamic>) {
      categoryId = (widget.product.category as Map<String, dynamic>)['_id'];
    } else if (widget.product.categoryId != null) {
      categoryId = widget.product.categoryId;
    } else {
      debugPrint("No valid category ID available for the product.");
      return;
    }

    setState(() {
      isLoadingRelated = true;
    });

    try {
      debugPrint("Fetching related products for category: $categoryId");
      final response = await http.get(
        Uri.parse(
            'https://pa-gebeya-backend.onrender.com/api/products/category/$categoryId'),
      );

      debugPrint("API Response: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final productsData = responseData is List
            ? responseData
            : responseData['products'] ?? [];

        debugPrint("Products data: $productsData");

        final filteredProducts = (productsData as List)
            .where((p) => p['_id'] != widget.product.id)
            .map((p) => Product.fromJson(p))
            .toList();

        debugPrint("Filtered products: ${filteredProducts.length}");
        setState(() {
          relatedProducts = filteredProducts;
        });
      } else {
        throw Exception(
            'Failed to load related products: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error fetching related products: $error');
      Fluttertoast.showToast(
        msg: "Failed to load related products",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
      );
      setState(() {
        relatedProducts = [];
      });
    } finally {
      setState(() {
        isLoadingRelated = false;
      });
    }
  }

  Future<void> addToCart(Product product) async {
    debugPrint("🟢 addToCart called for product: ${product.id}");

    // Check stock quantity before proceeding
    if (product.stockQuantity != null && product.stockQuantity! <= 0) {
      debugPrint("🚨 Error: Product is out of stock!");
      showToast("This product is currently out of stock", error: true);
      return;
    }

    // Check if requested quantity exceeds available stock
    if (product.stockQuantity != null && quantity > product.stockQuantity!) {
      debugPrint("🚨 Error: Requested quantity exceeds available stock!");
      showToast(
        "Only ${product.stockQuantity} items available in stock",
        error: true,
      );
      return;
    }

    if (product.id == null || product.id!.isEmpty) {
      debugPrint("🚨 Error: Product ID is null or empty!");
      showToast("Error: Product ID is missing", error: true);
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

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
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['userId'] = userId;
    request.fields['productId'] = product.id!;
    request.fields['productName'] = product.title;
    request.fields['price'] = product.price.toString();
    request.fields['quantity'] = quantity.toString();

    if (product.images != null && product.images!.isNotEmpty) {
      request.fields['img'] = product.images!.first;
      debugPrint("🟢 Image URL added to request: ${product.images!.first}");
    }

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

  void showToast(String message, {bool error = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: error ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Widget buildRatingStars(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, size: 16, color: Colors.yellow);
        } else if (hasHalfStar && index == fullStars) {
          return Icon(Icons.star_half, size: 16, color: Colors.yellow);
        } else {
          return Icon(Icons.star, size: 16, color: Colors.grey);
        }
      }),
    );
  }

  String formatSoldCount(int? sold) {
    final soldCount = sold ?? 0;
    if (soldCount == 0) return '0 sold';
    if (soldCount < 10) return '$soldCount sold';
    return '${(soldCount ~/ 10) * 10}+ sold';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bottomPadding =
        context.bottomViewPadding == 0.0 ? 30.0 : context.bottomViewPadding;

    final categoryId = product.category is Map<String, dynamic>
        ? (product.category as Map<String, dynamic>)['_id']
        : product.categoryId;
    final categoryName = product.category is Map<String, dynamic>
        ? (product.category as Map<String, dynamic>)['name'] ?? 'Category'
        : product.category ?? 'Category';

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
                    if (product.stockQuantity != null)
                      Text(
                        product.stockQuantity! > 0
                            ? '${product.stockQuantity} items available'
                            : 'Out of stock',
                        style: context.bodySmall?.copyWith(
                          color: product.stockQuantity! > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                  ],
                ),
                Text(
                    '\$${(double.parse(product.price) * quantity).toStringAsFixed(2)}',
                    style: context.bodyLargeW600)
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    product.stockQuantity != null && product.stockQuantity! <= 0
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed:
                  product.stockQuantity != null && product.stockQuantity! <= 0
                      ? null
                      : () => addToCart(widget.product),
              child: Text(
                product.stockQuantity != null && product.stockQuantity! <= 0
                    ? 'Out of Stock'
                    : 'Add to Cart',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
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
                  child: const Icon(Icons.favorite_border),
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
                        onCartUpdated: () {},
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
                    child: const Icon(Icons.shopping_cart),
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
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 100),
                ),
              ),
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
                        Text(categoryName, style: context.bodySmall),
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
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          if (widget.product.images != null &&
              widget.product.images!.isNotEmpty)
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
                          image: DecorationImage(
                            image: NetworkImage(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10.0),
                  itemCount: widget.product.images!.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 5)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10.0),
                  Text(
                    product.shortDescription ??
                        'No short description available',
                    style: context.bodyMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  if (product.fullDescription != null)
                    Text(
                      product.fullDescription!,
                      style: context.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
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
                          onPressed: product.stockQuantity != null &&
                                  quantity >= product.stockQuantity!
                              ? null
                              : () {
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Related Products',
                    style: context.bodyLargeW600,
                  ),
                  const SizedBox(height: 10),
                  isLoadingRelated
                      ? const Center(child: CircularProgressIndicator())
                      : relatedProducts.isEmpty
                          ? Column(
                              children: [
                                const Text('No related products found.'),
                              ],
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 10.0,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: relatedProducts.length,
                              itemBuilder: (context, index) {
                                final relatedProduct = relatedProducts[index];

                                if (!_pageControllers
                                    .containsKey(relatedProduct.id!)) {
                                  _pageControllers[relatedProduct.id!] =
                                      PageController();
                                  _startAutoScroll(relatedProduct.id!,
                                      relatedProduct.images?.length ?? 1);
                                }

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProductDetailsScreen(
                                          product: relatedProduct,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin: const EdgeInsets.all(0),
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 120,
                                                child: PageView.builder(
                                                  controller: _pageControllers[
                                                      relatedProduct.id],
                                                  itemCount: relatedProduct
                                                          .images?.length ??
                                                      1,
                                                  itemBuilder:
                                                      (context, imageIndex) {
                                                    return ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: Image.network(
                                                        relatedProduct.images?[
                                                                imageIndex] ??
                                                            relatedProduct
                                                                .thumbnailPath!,
                                                        height: 120,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return const Icon(
                                                              Icons
                                                                  .image_not_supported,
                                                              size: 100);
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.yellow,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      '$categoryName Product',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      relatedProduct.title,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                relatedProduct
                                                        .shortDescription ??
                                                    'No description available',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  buildRatingStars(
                                                      relatedProduct.rating ??
                                                          0),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '| ${relatedProduct.rating ?? 0}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '| ${formatSoldCount(relatedProduct.sold)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'ETB ${relatedProduct.price}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (relatedProduct.videoLink != null &&
                                            relatedProduct
                                                .videoLink!.isNotEmpty)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                launchUrl(Uri.parse(
                                                    relatedProduct.videoLink!));
                                              },
                                              child: RotationTransition(
                                                turns: _animationController,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.tiktok,
                                                    color: Colors.black,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
        ],
      ),
    );
  }
}
