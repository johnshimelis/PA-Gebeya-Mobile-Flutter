import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
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
    with SingleTickerProviderStateMixin {
  late Future<List<ProductDetail>> futureProducts;
  List<ProductDetail> allProducts = [];
  List<ProductDetail> displayedProducts = [];
  int itemsToShow = 50;
  Map<String, int> cartItems = {};
  bool isLoggedIn = false;
  String? userId;
  late AnimationController _animationController;
  final Map<String, PageController> _pageControllers = {};
  final Map<String, Timer> _timers = {};

  String _getFullImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    return 'https://pa-gebeya-upload.s3.eu-north-1.amazonaws.com/$imagePath';
  }

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
    checkLoginStatus();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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

  bool isTokenExpired(String? token) {
    if (token == null) return true;
    try {
      final parts = token.split(".");
      if (parts.length != 3) {
        throw Exception("Invalid JWT structure");
      }
      String payload = parts[1];
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
      return true;
    }
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedToken = prefs.getString('token');
    userId = prefs.getString('userId');

    if (storedToken != null &&
        storedToken.isNotEmpty &&
        !isTokenExpired(storedToken)) {
      setState(() => isLoggedIn = true);
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
    try {
      final response = await http
          .get(
            Uri.parse('https://pa-gebeya-backend.onrender.com/api/products/'),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint("🔹 API Response Status: ${response.statusCode}");
      debugPrint("🔹 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        debugPrint("🟢 Raw Product Data: ${data}");
        List<ProductDetail> products = data
            .map((item) => ProductDetail.fromJson(item as Map<String, dynamic>))
            .toList();

        setState(() {
          allProducts = products;
          displayedProducts = allProducts.take(itemsToShow).toList();
        });

        return products;
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error fetching products: $e");
      throw Exception('Failed to load products: $e');
    }
  }

  Future<void> addToCart(ProductDetail product) async {
    debugPrint("🟢 addToCart called for product: ${product.id}");

    if (product.id == null || product.id!.isEmpty) {
      debugPrint("🚨 Error: Product ID is null or empty!");
      showToast("Error: Product ID is missing", error: true);
      return;
    }

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
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['userId'] = storedUserId;
    request.fields['productId'] = product.id!;
    request.fields['productName'] = product.name;
    request.fields['price'] = product.price.toString();
    request.fields['quantity'] = (cartItems[product.id] ?? 1).toString();

    if (product.photo != null && product.photo!.isNotEmpty) {
      request.fields['img'] = product.photo!;
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
      } else {
        cartItems[productId] = (currentQuantity > 1) ? currentQuantity - 1 : 0;
      }

      if (cartItems[productId]! <= 0) {
        cartItems.remove(productId);
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
      timeInSecForIosWeb: 3,
    );
  }

  void _loadMoreProducts() {
    setState(() {
      int nextCount = displayedProducts.length + 10;
      displayedProducts = allProducts.take(nextCount).toList();
    });
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

                    debugPrint(
                        "🟢 Loading images for ${product.name}: $fullImageUrls");

                    if (!_pageControllers.containsKey(product.id)) {
                      _pageControllers[product.id!] = PageController();
                      if (fullImageUrls.length > 1) {
                        _startAutoScroll(product.id!, fullImageUrls.length);
                      }
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
                                      controller: _pageControllers[product.id],
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
                                            headers: {
                                              'Accept': 'image/*',
                                            },
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
                                              debugPrint(
                                                  "❌ Error loading image: $error");
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
                                                    Text("Image not available",
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
                                        child: Text(
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
                                      buildRatingStars(product.rating ?? 0),
                                      const SizedBox(width: 4),
                                      Text(
                                        '| ${product.rating ?? 0}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '| ${product.sold ?? 0} sold',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'ETB ${product.price}',
                                    style: TextStyle(
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
