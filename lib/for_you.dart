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

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  _ForYouScreenState createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<List<ProductDetail>> futureProducts = Future.value([]);
  List<ProductDetail> allProducts = [];
  List<ProductDetail> displayedProducts = [];
  int itemsToShow = 50;
  bool isLoggedIn = false;
  String? userId;
  String? authToken;
  late AnimationController _animationController;
  final Map<String, Timer> _timers = {};
  final String _productsCacheKey = 'cached_foryou_products';

  String _getFullImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    return 'https://pa-gebeya-upload.s3.eu-north-1.amazonaws.com/$imagePath';
  }

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
    for (var timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<List<ProductDetail>> _fetchProductsWithCacheFallback() async {
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

  Future<List<ProductDetail>> _fetchProductsFromNetwork() async {
    try {
      final response = await http.get(
        Uri.parse('https://pa-gebeya-backend.onrender.com/api/products/'),
        headers: {
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint("🟢 Fetched ${data.length} products from network");
        return data.map((item) => ProductDetail.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Network fetch error: $e');
      rethrow;
    }
  }

  Future<List<ProductDetail>?> _getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_productsCacheKey);
      if (cachedData == null) return null;

      final List<dynamic> jsonList = jsonDecode(cachedData);
      return jsonList.map((json) => ProductDetail.fromJson(json)).toList();
    } catch (e) {
      debugPrint("❌ Error reading cached products: $e");
      return null;
    }
  }

  Future<void> _cacheProducts(List<ProductDetail> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productJsonList =
          products.map((p) => _productDetailToJson(p)).toList();
      await prefs.setString(_productsCacheKey, jsonEncode(productJsonList));
      debugPrint("✅ Cached ${products.length} products");
    } catch (e) {
      debugPrint("❌ Error caching products: $e");
    }
  }

  Map<String, dynamic> _productDetailToJson(ProductDetail product) {
    return {
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'photo': product.photo,
      'shortDescription': product.shortDescription,
      'fullDescription': product.fullDescription,
      'rating': product.rating,
      'sold': product.sold,
      'videoLink': product.videoLink,
      'images': product.images,
      'category': product.category,
      'brand': product.brand,
      'discount': product.discount,
      'oldPrice': product.oldPrice,
    };
  }

  Future<void> _refreshProducts() async {
    setState(() {
      futureProducts = _fetchProductsWithCacheFallback().then((products) {
        if (products.isNotEmpty) {
          allProducts = products;
          displayedProducts = allProducts.take(itemsToShow).toList();
        }
        return products;
      });
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

  void _startAutoScroll(PageController controller, int imageCount) {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (controller.hasClients) {
        if (controller.page ==
            (controller.position.maxScrollExtent / 200).floor()) {
          controller.animateToPage(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          controller.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
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

  void _loadMoreProducts() {
    setState(() {
      int nextCount = displayedProducts.length + 10;
      displayedProducts = allProducts.take(nextCount).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<ProductDetail>>(
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

        if (allProducts.isEmpty && snapshot.data!.isNotEmpty) {
          allProducts = snapshot.data!;
          displayedProducts = allProducts.take(itemsToShow).toList();
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Headline(
                headline: 'For You',
                onViewAllTap: _refreshProducts,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final product = displayedProducts[index];
                    final imageUrls = product.images ?? [product.photo ?? ''];
                    final fullImageUrls =
                        imageUrls.map(_getFullImageUrl).toList();

                    // Create a new controller for each PageView
                    final pageController = PageController();

                    // Start auto-scroll if there are multiple images
                    if (fullImageUrls.length > 1) {
                      _startAutoScroll(pageController, fullImageUrls.length);
                    }

                    return GestureDetector(
                      onTap: () {
                        final productToPass = Product(
                          id: product.id,
                          title: product.name,
                          price: product.price.toString(),
                          thumbnailPath: _getFullImageUrl(product.photo ?? ''),
                          shortDescription: product.shortDescription,
                          fullDescription: product.fullDescription ?? '',
                          rating: product.rating ?? 0,
                          sold: product.sold ?? 0,
                          videoLink: product.videoLink,
                          images: fullImageUrls,
                          category: product.category?['name'],
                          brand: product.brand,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailsScreen(product: productToPass),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 120,
                                    child: PageView.builder(
                                      controller: pageController,
                                      itemCount: fullImageUrls.length,
                                      itemBuilder: (context, imageIndex) {
                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            fullImageUrls[imageIndex],
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (context, child, progress) {
                                              if (progress == null)
                                                return child;
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: progress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? progress
                                                              .cumulativeBytesLoaded /
                                                          progress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.broken_image,
                                                        size: 40,
                                                        color:
                                                            Colors.grey[400]),
                                                    const SizedBox(height: 5),
                                                    const Text(
                                                        "Image not available",
                                                        style: TextStyle(
                                                            fontSize: 12)),
                                                  ],
                                                ),
                                              );
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'For You',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          product.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                Theme.of(context).brightness ==
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
                                  const SizedBox(height: 6),
                                  Text(
                                    product.shortDescription,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      buildRatingStars(product.rating ?? 0),
                                      const SizedBox(width: 4),
                                      Text(
                                        '| ${product.rating ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '| ${product.sold ?? 0} sold',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'ETB ${product.price}',
                                    style: const TextStyle(
                                      fontSize: 14,
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
                                  onTap: () => launchUrl(product.videoLink!),
                                  child: RotationTransition(
                                    turns: _animationController,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
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
                    );
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
