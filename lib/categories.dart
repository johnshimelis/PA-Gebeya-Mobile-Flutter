import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:laza/brand_products_screen.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/models/brand.dart';
import 'package:laza/components/laza_icons.dart';

class Categories extends StatelessWidget {
  const Categories({super.key});

  Future<List<AppCategory>> fetchCategories() async {
    final response = await http.get(
        Uri.parse("https://pa-gebeya-backend.onrender.com/api/categories"));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      // Debugging: Print all categories fetched
      for (var category in data) {
        print("Fetched Category: ${jsonEncode(category)}");
      }

      return data.map((json) => AppCategory.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10.0),
        Headline(
          headline: 'Categories',
          onViewAllTap: () {},
        ),
        FutureBuilder<List<AppCategory>>(
          future: fetchCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No categories available"));
            }

            final categories = snapshot.data!;
            final int mid = (categories.length / 2).ceil();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(
                        mid,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: CategoryTile(category: categories[index]),
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(
                        categories.length - mid,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child:
                              CategoryTile(category: categories[index + mid]),
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
              fontSize: 24, // Increased size
              fontWeight: FontWeight.bold, // Made bold
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
  const CategoryTile({super.key, required this.category});
  final AppCategory category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final brand =
            Brand(category.name, LazaIcons.adidas_logo); // Use a default icon
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BrandProductsScreen(brand: brand)),
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
            Text(
              category.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AppCategory {
  final String name;
  final String? image;

  AppCategory({required this.name, this.image});

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      name: json['name'],
      image: json['image'], // Use the image URL directly from the API response
    );
  }
}
