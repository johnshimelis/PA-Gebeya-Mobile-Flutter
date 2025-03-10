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
import 'package:laza/my_cards_screen.dart';
import 'package:laza/orders_screen.dart'; // Add this import for OrdersScreen
import 'package:laza/chat_screen.dart'; // Add this import for ChatScreen
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';

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
            children: const [
              HomeScreen(),
              OrdersScreen(), // Replace WishlistScreen with OrdersScreen
              CartScreen(),
              ChatScreen(), // Replace MyCardsScreen with ChatScreen
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 56,
                child: SlidingClippedNavBar(
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
                      icon:
                          Icons.home, // Replace LazaIcons.home with Icons.home
                      title: 'Home',
                    ),
                    BarItem(
                      icon: Icons
                          .chat, // Replace LazaIcons.wallet with Icons.chat
                      title: 'Chat', // Replace My Cards with Chat
                    ),
                    BarItem(
                      icon: Icons
                          .shopping_cart, // Replace LazaIcons.bag with Icons.shopping_cart
                      title: 'Cart',
                    ),
                    BarItem(
                      icon: Icons
                          .shopping_bag, // Replace LazaIcons.heart with Icons.shopping_bag
                      title: 'Orders', // Replace Wishlist with Orders
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(bottom: context.bottomViewPadding),
                color: bottomBarBgColor,
              )
            ],
          ),
        ),
      ),
    );
  }
}
