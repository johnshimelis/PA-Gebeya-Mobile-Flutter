import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laza/brand_products_screen.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/models/brand.dart';
import 'package:laza/components/laza_icons.dart';

class Categories extends StatefulWidget {
  const Categories({super.key, required this.onCartUpdated});
  final VoidCallback onCartUpdated;

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Future<List<AppCategory>> _categoriesFuture;
  final String _categoriesCacheKey = 'cached_categories';
  String? authToken;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = Future.value([]); // Initialize with empty future
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _checkAuthStatus();
    setState(() {
      _categoriesFuture = _fetchCategoriesWithCacheFallback();
    });
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('token');
  }

  Future<List<AppCategory>> _fetchCategoriesWithCacheFallback() async {
    // First try to get cached data
    final cachedCategories = await _getCachedCategories();

    try {
      final freshCategories = await _fetchCategoriesFromNetwork();
      await _cacheCategories(freshCategories);
      return freshCategories;
    } catch (e) {
      debugPrint("❌ Network error: $e");
      if (cachedCategories != null && cachedCategories.isNotEmpty) {
        debugPrint("⚠️ Using cached categories as fallback");
        return cachedCategories;
      }
      return [];
    }
  }

  Future<List<AppCategory>> _fetchCategoriesFromNetwork() async {
    try {
      final response = await http.get(
        Uri.parse("https://pa-gebeya-backend.onrender.com/api/categories"),
        headers: {
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint("🟢 Fetched ${data.length} categories from network");
        return data.map((json) => AppCategory.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load categories: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('❌ Network fetch error: $e');
      rethrow;
    }
  }

  Future<List<AppCategory>?> _getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_categoriesCacheKey);
      if (cachedData == null) return null;
      return (jsonDecode(cachedData) as List)
          .map((item) => AppCategory.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint("❌ Error reading cached categories: $e");
      return null;
    }
  }

  Future<void> _cacheCategories(List<AppCategory> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_categoriesCacheKey,
          jsonEncode(categories.map((c) => c.toJson()).toList()));
      debugPrint("✅ Cached ${categories.length} categories");
    } catch (e) {
      debugPrint("❌ Error caching categories: $e");
    }
  }

  Future<void> _refreshCategories() async {
    setState(() {
      _categoriesFuture = _fetchCategoriesWithCacheFallback();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        const SizedBox(height: 10.0),
        Headline(
          headline: 'Categories',
          onViewAllTap: _refreshCategories,
        ),
        FutureBuilder<List<AppCategory>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    Text("Error: ${snapshot.error.toString()}"),
                    ElevatedButton(
                      onPressed: _refreshCategories,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
              return const Center(child: Text("No categories available"));
            }

            // Split categories into two rows
            final midPoint = (categories.length / 2).ceil();
            final firstRow = categories.sublist(0, midPoint);
            final secondRow = categories.sublist(midPoint);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                children: [
                  // First row
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      itemCount: firstRow.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: CategoryTile(
                          category: firstRow[index],
                          onCartUpdated: widget.onCartUpdated,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Second row
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      itemCount: secondRow.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: CategoryTile(
                          category: secondRow[index],
                          onCartUpdated: widget.onCartUpdated,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            headline,
            style: context.bodyLargeW500?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onViewAllTap,
            child: Text(
              'View All',
              style: context.bodySmall?.copyWith(color: ColorConstant.manatee),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.onCartUpdated,
  });
  final AppCategory category;
  final VoidCallback onCartUpdated;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final brand = Brand(
          category.name,
          LazaIcons.adidas_logo,
          categoryId: category.id,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrandProductsScreen(
              brand: brand,
              categoryId: category.id,
              onCartUpdated: onCartUpdated,
            ),
          ),
        );
      },
      borderRadius: const BorderRadius.all(Radius.circular(10.0)),
      child: Ink(
        height: 100,
        width: 85,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: category.image != null
                    ? DecorationImage(
                        image: NetworkImage(category.image!),
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(color: Colors.transparent),
              ),
            ),
            const SizedBox(height: 6.0),
            Flexible(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppCategory {
  final String id;
  final String name;
  final String? image;

  AppCategory({required this.id, required this.name, this.image});

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Category',
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'image': image,
      };
}
