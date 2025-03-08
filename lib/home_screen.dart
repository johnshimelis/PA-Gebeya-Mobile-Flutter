import 'package:flutter/material.dart';
import 'package:laza/brand_products_screen.dart';
import 'package:laza/cart_screen.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/dashboard.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/search_screen.dart';
import 'Ads.dart'; // Import the Ads widget
import 'discountAds.dart'; // Import the DiscountAds widget
import 'for_you.dart';
import 'discount.dart'; // Import the DiscountScreen widget
import 'categories.dart'; // Import the categories.dart widget
import 'bestseller.dart'; // Import BestsellerScreen
import 'components/laza_icons.dart';
import 'forYouAds.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const inputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        borderSide: BorderSide(width: 0, color: Colors.transparent));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: HomeAppBar(), // Updated to use a proper AppBar
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'search',
                      child: Material(
                        color: Colors.transparent,
                        child: TextField(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SearchScreen(),
                                  fullscreenDialog: true)),
                          readOnly: true,
                          decoration: InputDecoration(
                              filled: true,
                              hintText: 'Search ...',
                              contentPadding: EdgeInsets.zero,
                              border: inputBorder,
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder,
                              hintStyle:
                                  TextStyle(color: ColorConstant.manatee),
                              fillColor: context.theme.cardColor,
                              prefixIcon: Icon(LazaIcons.search,
                                  color: ColorConstant.manatee)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Hero(
                    tag: 'voice',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10.0)),
                        onTap: () {},
                        child: Ink(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                              color: ColorConstant.primary,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0))),
                          child: const Icon(LazaIcons.voice,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            Ads(), // Horizontal auto-scrolling ads
            const SizedBox(height: 20.0),

            Categories(), // Categories widget (from categories.dart)
            const SizedBox(height: 20.0),

            // Bestseller Section
            BestsellerScreen(),
            const SizedBox(
                height:
                    40.0), // Increased gap between Bestseller and DiscountAds

            // Discount Ads Section
            DiscountAds(),
            const SizedBox(height: 40.0),

            // Discount Section
            DiscountScreen(),
            const SizedBox(height: 40.0),

            Foryouads(),
            const SizedBox(height: 40.0),

            ForYouScreen(),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }
}

class HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false, // Removed the back icon
      title: Row(
        children: [
          InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            onTap: () {
              dashboardScaffoldKey.currentState?.openDrawer();
            },
            child: Ink(
              width: 45,
              height: 45,
              decoration: ShapeDecoration(
                color: context.theme.cardColor,
                shape: const CircleBorder(),
              ),
              child: const Icon(LazaIcons.menu_horizontal, size: 13),
            ),
          ),
          const SizedBox(width: 15), // Increased space between menu and logo
          Image.asset(
            'assets/images/PA-Logos.png', // Ensure the correct path
            height: 40, // Small size
          ),
          const SizedBox(width: 5), // Space between logo and text
          const Text(
            'PA Gebeya',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const CartScreen()));
          },
          child: Ink(
            width: 45,
            height: 45,
            decoration: ShapeDecoration(
              color: context.theme.cardColor,
              shape: const CircleBorder(),
            ),
            child: const Icon(LazaIcons.bag),
          ),
        ),
        const SizedBox(width: 15),
      ],
    );
  }
}
