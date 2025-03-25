import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/models/brand.dart';
import 'package:laza/models/product.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/product_details.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class BrandProductsScreen extends StatefulWidget {
  const BrandProductsScreen({
    super.key,
    required this.brand,
    required this.categoryId,
    required this.onCartUpdated,
  });
  final Brand brand;
  final String categoryId;
  final VoidCallback onCartUpdated;

  @override
  State<BrandProductsScreen> createState() => _BrandProductsScreenState();
}

class _BrandProductsScreenState extends State<BrandProductsScreen>
    with SingleTickerProviderStateMixin {
  List<Product> products = [];
  bool isLoading = true;
  String errorMessage = '';
  final Map<String, PageController> _pageControllers = {};
  final Map<String, Timer> _timers = {};
  late AnimationController _animationController;
  int retryCount = 0;
  static const maxRetries = 3;

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing with category ID: ${widget.categoryId}");
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fetchProductsWithRetry();
  }

  @override
  void dispose() {
    for (var controller in _pageControllers.values) {
      controller.dispose();
    }
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchProductsWithRetry() async {
    try {
      await fetchProducts();
    } catch (e) {
      if (retryCount < maxRetries) {
        retryCount++;
        debugPrint("Retry attempt $retryCount after error: $e");
        await Future.delayed(const Duration(seconds: 2));
        _fetchProductsWithRetry();
      } else {
        setState(() {
          errorMessage =
              "Failed to load products. Please check your connection and try again.";
          isLoading = false;
        });
      }
    }
  }

  void _startAutoScroll(String productId, int imageCount) {
    _timers[productId] = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageControllers[productId]?.hasClients ?? false) {
        final currentPage = _pageControllers[productId]!.page ?? 0;
        final maxPage =
            (_pageControllers[productId]!.position.maxScrollExtent / 200)
                .floor();

        if (currentPage >= maxPage) {
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

  Future<void> fetchProducts() async {
    try {
      debugPrint("Fetching products for category: ${widget.categoryId}");
      final url = Uri.parse(
          "https://pa-gebeya-backend.onrender.com/api/products/category/${widget.categoryId}");

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      debugPrint("Products API Status: ${response.statusCode}");
      debugPrint("Products API Response: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is! Map<String, dynamic> ||
            !responseData.containsKey('products')) {
          throw Exception("Invalid API response format");
        }

        final productsData = responseData['products'] as List;

        if (productsData.isEmpty) {
          setState(() {
            errorMessage = "No products found in this category";
            isLoading = false;
          });
          return;
        }

        setState(() {
          products =
              productsData.map((json) => Product.fromJson(json)).toList();
          isLoading = false;
          errorMessage = '';
        });
      } else {
        throw Exception("Server responded with ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error in fetchProducts: $e");
      setState(() {
        errorMessage = "Error: ${e.toString().replaceAll('Exception: ', '')}";
        isLoading = false;
      });
      rethrow;
    }
  }

  void _showToast(String message, {Color backgroundColor = Colors.red}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = '';
                retryCount = 0;
              });
              _fetchProductsWithRetry();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(brand: widget.brand),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${products.length} Items',
                          style: context.bodyLargeW500),
                      const SizedBox(height: 4),
                      Text(
                        'Available in stock',
                        style: context.bodyMedium
                            ?.copyWith(color: ColorConstant.manatee),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: context.theme.cardColor,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sort,
                              size: 20, color: context.bodyMediumW500?.color),
                          const SizedBox(width: 8),
                          Text('Sort', style: context.bodyMediumW500),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage.isNotEmpty
                        ? _buildErrorWidget()
                        : products.isEmpty
                            ? const Center(child: Text("No products available"))
                            : GridView.builder(
                                shrinkWrap: true,
                                itemCount: products.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12.0,
                                  mainAxisSpacing: 16.0,
                                  childAspectRatio: 0.65,
                                ),
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  if (!_pageControllers
                                      .containsKey(product.id)) {
                                    _pageControllers[product.id!] =
                                        PageController();
                                    _startAutoScroll(product.id!,
                                        product.images?.length ?? 1);
                                  }
                                  return _ProductCard(
                                    product: product,
                                    pageController:
                                        _pageControllers[product.id]!,
                                    animationController: _animationController,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductDetailsScreen(
                                                  product: product),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final PageController pageController;
  final AnimationController animationController;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.pageController,
    required this.animationController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        product.discount != null && product.discount!.isNotEmpty;
    final price = double.tryParse(product.price) ?? 0;
    final discountValue =
        hasDiscount ? double.tryParse(product.discount!) ?? 0 : 0;
    final discountPrice =
        hasDiscount ? price - (price * discountValue / 100) : price;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 120,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: product.images?.length ?? 1,
                      itemBuilder: (context, index) {
                        final imageUrl = product.images != null &&
                                product.images!.isNotEmpty
                            ? product.images![index % product.images!.length]
                            : product.thumbnailPath;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (hasDiscount && discountValue > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${discountValue.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'For You',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.shortDescription ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRatingStars(product.rating ?? 0),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating?.toStringAsFixed(1) ?? '0'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${product.sold ?? 0} sold',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (hasDiscount && discountValue > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ETB ${discountPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'ETB ${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'ETB ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
              if (product.videoLink != null && product.videoLink!.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => launchUrl(Uri.parse(product.videoLink!)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: AnimatedBuilder(
                        animation: animationController,
                        builder: (_, child) => Transform.rotate(
                          angle: animationController.value * 2 * 3.14159,
                          child: child,
                        ),
                        child: const Icon(Icons.tiktok, size: 20),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, size: 16, color: Colors.yellow);
        } else if (hasHalfStar && index == fullStars) {
          return const Icon(Icons.star_half, size: 16, color: Colors.yellow);
        }
        return const Icon(Icons.star, size: 16, color: Colors.grey);
      }),
    );
  }
}

class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key, required this.brand});
  final Brand brand;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(brand.name),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
