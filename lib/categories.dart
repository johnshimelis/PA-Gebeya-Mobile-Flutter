import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:laza/brand_products_screen.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/models/brand.dart';
import 'package:laza/components/laza_icons.dart';

class Categories extends StatelessWidget {
  const Categories({super.key, required this.onCartUpdated});
  final VoidCallback onCartUpdated;

  Future<List<AppCategory>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse("https://pa-gebeya-backend.onrender.com/api/categories"),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint("Fetched ${data.length} categories");
        return data.map((json) => AppCategory.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load categories: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10.0),
        const Headline(
          headline: 'Categories',
          onViewAllTap: null,
        ),
        FutureBuilder<List<AppCategory>>(
          future: fetchCategories(),
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
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Categories(onCartUpdated: onCartUpdated),
                        ),
                      ),
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
                    height: 120, // Fixed height for consistent layout
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          firstRow.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: CategoryTile(
                              category: firstRow[index],
                              onCartUpdated: onCartUpdated,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Second row
                  SizedBox(
                    height: 120, // Fixed height for consistent layout
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          secondRow.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: CategoryTile(
                              category: secondRow[index],
                              onCartUpdated: onCartUpdated,
                            ),
                          ),
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
}
