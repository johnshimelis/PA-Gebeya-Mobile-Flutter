import 'dart:convert';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/intro_screen.dart';
import 'package:laza/theme.dart';
import 'package:provider/provider.dart';
import 'colors.dart';
import 'package:laza/sign_in_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  Future<bool> _isTokenExpired(String? token) async {
    if (token == null) return true;

    // Decode the token to get the expiration time
    final parts = token.split('.');
    if (parts.length != 3) {
      return true;
    }

    final payload = json
        .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

    // Check if the token has an expiration time
    if (payload['exp'] == null) {
      return true;
    }

    final expirationTime =
        DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
    final currentTime = DateTime.now();

    return currentTime.isAfter(expirationTime);
  }

  Future<String> _getUserName() async {
    // Load user data from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('userData'); // Retrieve the user data
    String? token = prefs.getString('token'); // Retrieve the token

    if (userJson != null && token != null) {
      // Check if the token is expired
      bool isExpired = await _isTokenExpired(token);

      if (isExpired) {
        // If token is expired, return "Guest User"
        return 'Guest User';
      }

      // If user is logged in and token is not expired, return the full name
      Map<String, dynamic> userData =
          json.decode(userJson); // Decode the user data
      String fullName = userData['fullName']; // Get the full name
      print("User details: $userData"); // Log the user data
      return fullName ?? 'Guest User'; // Return full name or 'Guest User'
    }
    // If user is not logged in, return "Guest User"
    return 'Guest User';
  }

  Future<void> _logout(BuildContext context) async {
    // Clear SharedPreferences when logging out
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs
        .clear(); // This will clear all the saved data, including user info.

    // After clearing, navigate to the IntroductionScreen (or login screen)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUserName(), // Fetch the username from SharedPreferences
      builder: (context, snapshot) {
        String displayName = 'Guest User'; // Default name for Guest User

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            displayName = snapshot.data ?? 'Guest User';
          }
        }

        return Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, top: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(50)),
                            onTap: () => Scaffold.of(context).closeDrawer(),
                            child: Ink(
                              width: 45,
                              height: 45,
                              decoration: ShapeDecoration(
                                color: context.theme.cardColor,
                                shape: const CircleBorder(),
                              ),
                              child:
                                  const Icon(Icons.more_vert), // Material Icon
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 20), // Adjust spacing
                            child: Image.asset(
                              'assets/images/PA-Logos.png', // Your image path
                              width: 100, // Adjust size as needed
                              height: 100,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  maxRadius: 24,
                                  child: Text('M'),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName, // Use the dynamic name here
                                        style: context.bodyLargeW500,
                                      ),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Verified Profile',
                                              style: context.bodySmall
                                                  ?.copyWith(
                                                      color: ColorConstant
                                                          .manatee),
                                            ),
                                          ),
                                          const SizedBox(width: 5.0),
                                          const Icon(
                                            Icons.verified, // Material Icon
                                            size: 15,
                                            color: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: context.theme.cardColor,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Text(
                              '3 Orders',
                              style: TextStyle(color: ColorConstant.manatee),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    Consumer<ThemeNotifier>(
                        builder: (context, themeNotifier, _) {
                      IconData iconData = Icons.brightness_auto;
                      switch (themeNotifier.themeMode) {
                        case ThemeMode.system:
                          iconData = Icons.brightness_auto_outlined;
                        case ThemeMode.light:
                          iconData = Icons.light_mode; // Material Icon
                        case ThemeMode.dark:
                          iconData = Icons.dark_mode_outlined;
                      }
                      return ListTile(
                        leading: Icon(iconData),
                        onTap: () async {
                          await showModalActionSheet(
                            context: context,
                            title: 'Choose app appearance',
                            actions: <SheetAction<ThemeMode>>[
                              const SheetAction(
                                  label: 'Automatic (follow system)',
                                  key: ThemeMode.system),
                              const SheetAction(
                                  label: 'Light', key: ThemeMode.light),
                              const SheetAction(
                                  label: 'Dark', key: ThemeMode.dark),
                            ],
                          ).then((result) {
                            if (result == null) return;

                            themeNotifier.toggleTheme(result);
                          });
                        },
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        title: const Text('Appearance'),
                        horizontalTitleGap: 10.0,
                      );
                    }),
                    ListTile(
                      leading: const Icon(Icons.info_outline), // Material Icon
                      onTap: () {},
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      title: const Text('Account Information'),
                      horizontalTitleGap: 10.0,
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock_outline), // Material Icon
                      onTap: () {},
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      title: const Text('Password'),
                      horizontalTitleGap: 10.0,
                    ),
                    ListTile(
                      leading: const Icon(
                          Icons.shopping_bag_outlined), // Material Icon
                      onTap: () {},
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      title: const Text('Order'),
                      horizontalTitleGap: 10.0,
                    ),
                    ListTile(
                      leading: const Icon(
                          Icons.credit_card_outlined), // Material Icon
                      onTap: () {},
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      title: const Text('My Cards'),
                      horizontalTitleGap: 10.0,
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.favorite_border), // Material Icon
                      onTap: () {},
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      title: const Text('Wishlist'),
                      horizontalTitleGap: 10.0,
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.settings_outlined), // Material Icon
                      onTap: () {},
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      title: const Text('Settings'),
                      horizontalTitleGap: 10.0,
                    ),
                  ],
                ),
                // Logout section
                Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout,
                          color: Colors.red), // Material Icon
                      onTap: () async {
                        await showOkCancelAlertDialog(
                          context: context,
                          title: 'Confirm Logout',
                          message: 'Are you sure you want to logout?',
                          isDestructiveAction: true,
                          okLabel: 'Logout',
                        ).then((result) {
                          if (result == OkCancelResult.ok) {
                            _logout(context); // Call logout
                          }
                        });
                      },
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                      title: const Text('Logout'),
                      horizontalTitleGap: 10.0,
                    ),
                    const SizedBox(height: 30.0),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
