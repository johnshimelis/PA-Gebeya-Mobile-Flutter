import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:laza/cart_screen.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/components/drawer.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/home_screen.dart';
import 'package:laza/orders_screen.dart';
import 'package:laza/chat_screen.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

var dashboardScaffoldKey = GlobalKey<ScaffoldState>();

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final pageController = PageController();
  int selectedIndex = 0;
  bool pop = false;

  // State variables for counts
  int cartItemCount = 0; // Initialize with 0
  int orderCount = 0; // Initialize with 0
  int chatCount = 0; // Initialize with 0 (if needed)

  @override
  void initState() {
    super.initState();
    // Fetch cart and order counts when the dashboard loads
    fetchCartItemCount();
    fetchOrderCount();
  }

  // Fetch cart item count
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
          cartItemCount = data['items'].length; // Update cart item count
        });
      }
    } catch (error) {
      debugPrint("Error fetching cart items: $error");
    }
  }

  // Fetch order count
  Future<void> fetchOrderCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    if (token == null || userId == null) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://pa-gebeya-backend.onrender.com/api/users/orders/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orderCount = data['orders'].length; // Update order count
        });
      }
    } catch (error) {
      debugPrint("Error fetching orders: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomBarBgColor =
        context.theme.bottomNavigationBarTheme.backgroundColor;
    final systemOverlay = context.theme.appBarTheme.systemOverlayStyle;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          systemOverlay!.copyWith(systemNavigationBarColor: bottomBarBgColor),
      child: WillPopScope(
        onWillPop: () async {
          if (Platform.isIOS) {
            return true;
          }
          if (pop) {
            return true;
          }
          Fluttertoast.showToast(msg: 'Press again to exit the app');
          pop = true;
          Timer(const Duration(seconds: 2), () {
            pop = false;
          });
          return false;
        },
        child: Scaffold(
          key: dashboardScaffoldKey,
          drawer: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5.0,
              sigmaY: 5.0,
            ),
            child: const DrawerWidget(),
          ),
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            children: [
              const HomeScreen(),
              const ChatScreen(),
              CartScreen(
                onCartUpdated:
                    fetchCartItemCount, // Pass callback to CartScreen
              ),
              OrdersScreen(
                onOrderUpdated: fetchOrderCount, // Pass the callback
              ),
            ],
          ),
          bottomNavigationBar: SizedBox(
            height: 70, // Adjust height as needed
            child: Stack(
              children: [
                SlidingClippedNavBar(
                  backgroundColor: bottomBarBgColor ?? Colors.white,
                  onButtonPressed: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                    pageController.jumpToPage(selectedIndex);
                  },
                  iconSize: 25,
                  activeColor: ColorConstant.primary,
                  inactiveColor: const Color(0xff8F959E),
                  selectedIndex: selectedIndex,
                  barItems: [
                    BarItem(
                      icon: Icons.home,
                      title: 'Home',
                    ),
                    BarItem(
                      icon: Icons.chat,
                      title: 'Chat',
                    ),
                    BarItem(
                      icon: Icons.shopping_cart,
                      title: 'Cart',
                    ),
                    BarItem(
                      icon: Icons.shopping_bag,
                      title: 'Orders',
                    ),
                  ],
                ),
                // Badges for chat, cart, and orders
                if (chatCount > 0)
                  Positioned(
                    top: 5,
                    left: MediaQuery.of(context).size.width * 0.25 +
                        20, // Adjusted to the right
                    child: _buildBadge(chatCount),
                  ),
                if (cartItemCount > 0)
                  Positioned(
                    top: 5,
                    left: MediaQuery.of(context).size.width * 0.6 +
                        20, // Adjusted to the right
                    child: _buildBadge(cartItemCount),
                  ),
                if (orderCount > 0)
                  Positioned(
                    top: 5,
                    left: MediaQuery.of(context).size.width * 0.84 +
                        20, // Adjusted to the right
                    child: _buildBadge(orderCount),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build a badge
  Widget _buildBadge(int count) {
    return Container(
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
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
