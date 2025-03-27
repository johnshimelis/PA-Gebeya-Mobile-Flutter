import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laza/models/index.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/product_details.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class BestsellerScreen extends StatefulWidget {
  const BestsellerScreen({super.key});

  @override
  _BestsellerScreenState createState() => _BestsellerScreenState();
}

class _BestsellerScreenState extends State<BestsellerScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<List<Product>> futureProducts = Future.value([]);
  bool isLoggedIn = false;
  String? userId;
  String? authToken;
  late AnimationController _animationController;
  final Map<String, PageController> _pageControllers = {};
  final Map<String, Timer> _timers = {};
  final String _productsCacheKey = 'cached_bestseller_products';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await checkLoginStatus();
    futureProducts = _fetchProductsWithCacheFallback();
    if (mounted) setState(() {});
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

  Future<List<Product>> _fetchProductsWithCacheFallback() async {
    try {
      final freshProducts = await _fetchProductsFromNetwork();
      await _cacheProducts(freshProducts);
      return freshProducts;
    } catch (e) {
      debugPrint("❌ Network error: $e");
      final cachedProducts = await _getCachedProducts();
      if (cachedProducts != null && cachedProducts.isNotEmpty) {
        debugPrint("⚠️ Using cached products as fallback");
        return cachedProducts;
      }
      return [];
    }
  }

  Future<List<Product>> _fetchProductsFromNetwork() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://pa-gebeya-backend.onrender.com/api/products/bestsellers'),
        headers: {
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint("🟢 Fetched ${data.length} fresh products from network");
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Network fetch error: $e');
      rethrow;
    }
  }

  Future<List<Product>?> _getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_productsCacheKey);
      if (cachedData == null) return null;
      return (jsonDecode(cachedData) as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint("❌ Error reading cached products: $e");
      return null;
    }
  }

  Future<void> _cacheProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_productsCacheKey,
          jsonEncode(products.map((p) => p.toJson()).toList()));
      debugPrint("✅ Cached ${products.length} products");
    } catch (e) {
      debugPrint("❌ Error caching products: $e");
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      futureProducts = _fetchProductsWithCacheFallback();
    });
  }

  Future<void> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('token');
      userId = prefs.getString('userId');

      if (authToken != null &&
          authToken!.isNotEmpty &&
          !isTokenExpired(authToken)) {
        setState(() => isLoggedIn = true);
        debugPrint("✅ User is logged in: userId=$userId");
      } else {
        setState(() {
          isLoggedIn = false;
          userId = null;
        });
        debugPrint("🚨 User is not logged in or token expired.");
      }
    } catch (e) {
      debugPrint("❌ Error checking login status: $e");
    }
  }

  bool isTokenExpired(String? token) {
    if (token == null) return true;
    try {
      final parts = token.split(".");
      if (parts.length != 3) throw Exception("Invalid JWT structure");
      String payload = parts[1];
      while (payload.length % 4 != 0) payload += '=';
      final decodedPayload = utf8.decode(base64Url.decode(payload));
      final payloadMap = json.decode(decodedPayload);
      final exp = payloadMap["exp"] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= exp;
    } catch (e) {
      debugPrint("❌ Error decoding token: $e");
      return true;
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
          return const Icon(Icons.star, size: 16, color: Colors.yellow);
        } else if (hasHalfStar && index == fullStars) {
          return const Icon(Icons.star_half, size: 16, color: Colors.yellow);
        } else {
          return const Icon(Icons.star, size: 16, color: Colors.grey);
        }
      }),
    );
  }

  Future<void> launchUrl(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        showToast("Could not launch $url", error: true);
      }
    } catch (e) {
      debugPrint("❌ Error launching URL: $e");
      showToast("Error launching URL. Please try again.", error: true);
    }
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Headline(
          headline: 'Best Sellers',
          onViewAllTap: _refreshProducts,
        ),
        SizedBox(
          height: 300,
          child: FutureBuilder<List<Product>>(
            future: futureProducts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _refreshProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No products available'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _refreshProducts,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                );
              }

              final products = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _refreshProducts,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 10.0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final imageUrls = product.images ?? [product.thumbnailPath];

                    if (!_pageControllers.containsKey(product.id)) {
                      _pageControllers[product.id!] = PageController();
                      if (imageUrls.length > 1) {
                        _startAutoScroll(product.id!, imageUrls.length);
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailsScreen(product: product),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: SizedBox(
                          width: 210,
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 120,
                                        child: PageView.builder(
                                          controller:
                                              _pageControllers[product.id],
                                          itemCount: imageUrls.length,
                                          itemBuilder: (context, imageIndex) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                imageUrls[imageIndex],
                                                height: 120,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        size: 100),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.yellow,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Bestseller',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              product.title,
                                              style:
                                                  context.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        product.shortDescription ??
                                            'No description available',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          buildRatingStars(product.rating ?? 0),
                                          const SizedBox(width: 5),
                                          Text(
                                            '| ${product.rating ?? 0}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '| ${product.sold ?? 0} sold',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'ETB ${product.price}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (product.videoLink != null &&
                                    product.videoLink!.isNotEmpty)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () =>
                                          launchUrl(product.videoLink!),
                                      child: RotationTransition(
                                        turns: _animationController,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.tiktok,
                                            color: Colors.black,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
            style: context.headlineMedium?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
