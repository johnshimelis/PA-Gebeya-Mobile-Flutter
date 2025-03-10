import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Import dart:convert for base64Url
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
import 'forYouAds.dart';
import 'sign_in_with_phone_number.dart'; // Import the sign-in screen

// Helper function to check if the user is logged in
Future<bool> isUserLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();

  // Retrieve the token and user ID from SharedPreferences
  final String? token = prefs.getString('token');
  final String? userId = prefs.getString('userId');

  // Debug logs
  print('✅ Retrieved userId: $userId');
  print('✅ Retrieved token: $token');

  // Check if the token and user ID exist
  if (token == null || userId == null) {
    print('❌ User is not logged in: Missing data');
    return false; // User is not logged in
  }

  // Check if the token is expired
  if (_isTokenExpired(token)) {
    print('❌ User is not logged in: Token expired');
    return false; // Token is expired
  }

  print('✅ User is logged in: userId=$userId');
  return true; // User is logged in and token is valid
}

// Check if the token has expired
bool _isTokenExpired(String token) {
  try {
    final payload = _decodeJwt(token);
    if (payload['exp'] == null) {
      print("❌ Token does not contain an expiration field.");
      return true; // Assume expired if no expiration field
    }

    final expTimestamp = payload['exp'] * 1000; // Convert to milliseconds
    final expirationDate =
        DateTime.fromMillisecondsSinceEpoch(expTimestamp, isUtc: true);
    final now = DateTime.now().toUtc();

    print('🕒 Token Expiration Time (UTC): $expirationDate');
    print('🕒 Current Time (UTC): $now');

    bool isExpired = now.isAfter(expirationDate);
    print('🚨 Token Expired? $isExpired');

    return isExpired;
  } catch (e) {
    print("❌ Error decoding token: $e");
    return true; // Assume expired if there's an error
  }
}

// Decode JWT token
Map<String, dynamic> _decodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception("Invalid JWT structure");

    final payload = base64Url.decode(base64Url.normalize(parts[1]));
    final decodedPayload = utf8.decode(payload);

    return json.decode(decodedPayload);
  } catch (e) {
    print("❌ JWT Decoding Error: $e");
    throw Exception("Failed to decode JWT");
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final loggedIn = await isUserLoggedIn();
    setState(() {
      isLoggedIn = loggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    const inputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        borderSide: BorderSide(width: 0, color: Colors.transparent));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: HomeAppBar(isLoggedIn: isLoggedIn),
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
                              prefixIcon:
                                  Icon(Icons.search, // Material search icon
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
                          child: const Icon(Icons.mic, // Material mic icon
                              color: Colors.white,
                              size: 22),
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
      // Add a big red phone call floating button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add functionality for the phone call button
          debugPrint('Phone call button pressed');
        },
        backgroundColor: Colors.red, // Red color for the button
        child:
            const Icon(Icons.call, size: 30, color: Colors.white), // Call icon
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Position at the bottom right
    );
  }
}

class HomeAppBar extends StatelessWidget {
  final bool isLoggedIn;

  const HomeAppBar({super.key, required this.isLoggedIn});

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
              child: const Icon(Icons.menu, size: 24), // Material menu icon
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
            if (isLoggedIn) {
              // Navigate to notifications screen
              // Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            } else {
              // Navigate to sign-in screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignInWithPhoneNumber(),
                ),
              );
            }
          },
          child: Ink(
            width: 45,
            height: 45,
            decoration: ShapeDecoration(
              color: context.theme.cardColor,
              shape: const CircleBorder(),
            ),
            child: Icon(
              isLoggedIn ? Icons.notifications : Icons.login, // Material icons
            ),
          ),
        ),
        const SizedBox(width: 15),
      ],
    );
  }
}
