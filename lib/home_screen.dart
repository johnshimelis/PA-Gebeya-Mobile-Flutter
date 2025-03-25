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
import 'package:http/http.dart' as http;
import 'discount.dart'; // Import the DiscountScreen widget
import 'categories.dart'; // Import the categories.dart widget
import 'bestseller.dart'; // Import BestsellerScreen
import 'forYouAds.dart';
import 'sign_in_with_phone_number.dart'; // Import the sign-in screen
import 'notifications.dart';
import 'package:url_launcher/url_launcher.dart';

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
  int notificationCount = 0; // Initialize with 0

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    fetchNotificationCount(); // Fetch notification count when the screen loads
  }

  Future<void> checkLoginStatus() async {
    final loggedIn = await isUserLoggedIn();
    setState(() {
      isLoggedIn = loggedIn;
    });
  }

  // Fetch notification count
  Future<void> fetchNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final String? userId = prefs.getString('userId');

    if (token == null || userId == null) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://pa-gebeya-backend.onrender.com/api/users/notifications/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notificationCount =
              data['notifications'].length; // Update notification count
        });
      }
    } catch (error) {
      debugPrint("Error fetching notifications: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    const inputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        borderSide: BorderSide(width: 0, color: Colors.transparent));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: HomeAppBar(
          isLoggedIn: isLoggedIn,
          notificationCount: notificationCount, // Pass the notification count
          onNotificationUpdated: fetchNotificationCount, // Pass the callback
        ),
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
                                  TextStyle(color: Theme.of(context).hintColor),
                              fillColor: Theme.of(context).cardColor,
                              prefixIcon: Icon(Icons.search,
                                  color: Theme.of(context).hintColor)),
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
                              color: Theme.of(context).primaryColor,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0))),
                          child: Icon(Icons.mic, color: Colors.white, size: 22),
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

            Categories(
              onCartUpdated: fetchCartItemCount, // Pass the callback
            ), // Categories widget (from categories.dart)
            const SizedBox(height: 20.0),

            // Bestseller Section
            BestsellerScreen(),
            const SizedBox(height: 40.0),

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
        onPressed: () async {
          // Phone number to call
          const phoneNumber = '+25176092990';
          final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

          // Check if the device can launch the URL
          if (await canLaunch(phoneUri.toString())) {
            await launch(phoneUri.toString()); // Launch the phone dialer
          } else {
            debugPrint('Could not launch $phoneUri');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not launch phone dialer.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        backgroundColor: Colors.red, // Red color for the button
        child: const Icon(Icons.call, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Position at the bottom right
    );
  }

  // Method to fetch cart item count
  Future<void> fetchCartItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    if (token == null || userId == null) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://pa-gebeya-backend.onrender.com/api/cart?userId=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Update cart item count in the Dashboard or other screens
        });
      }
    } catch (error) {
      debugPrint("Error fetching cart items: $error");
    }
  }
}

class HomeAppBar extends StatelessWidget {
  final bool isLoggedIn;
  final int notificationCount; // Add a notification count
  final VoidCallback onNotificationUpdated; // Add this callback

  const HomeAppBar({
    super.key,
    required this.isLoggedIn,
    this.notificationCount = 0,
    required this.onNotificationUpdated, // Add this parameter
  });

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
                color: Theme.of(context).cardColor,
                shape: const CircleBorder(),
              ),
              child: Icon(Icons.menu,
                  size: 24, color: Theme.of(context).iconTheme.color),
            ),
          ),
          const SizedBox(width: 15), // Increased space between menu and logo
          Image.asset(
            'assets/images/PA-Logos.png', // Ensure the correct path
            height: 40, // Small size
          ),
          const SizedBox(width: 5), // Space between logo and text
          Text(
            'PA Gebeya',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
      actions: [
        // Notification Icon with Badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(50)),
              onTap: () {
                if (isLoggedIn) {
                  // Navigate to notifications screen (without const)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(
                        onNotificationUpdated:
                            onNotificationUpdated, // Pass the callback
                      ),
                    ),
                  );
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
                  color: Theme.of(context).cardColor,
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  isLoggedIn ? Icons.notifications : Icons.login,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
            // Badge for Notifications
            if (notificationCount >
                0) // Only show badge if there are notifications
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle, // Make the badge fully circular
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 15),
      ],
    );
  }
}
