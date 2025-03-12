import 'package:flutter/material.dart';
import 'package:laza/splash_screen.dart';
import 'package:laza/theme.dart';
import 'package:provider/provider.dart';
import 'package:laza/order_confirmed_screen.dart'; // Import the OrderConfirmedScreen
import 'package:laza/sign_in_with_phone_number.dart'; // Import the SignInWithPhoneNumber screen
import 'package:laza/notifications.dart'; // Import the NotificationsScreen
import 'package:laza/order_detail_screen.dart'; // Import the OrderDetailScreen

// Define global keys
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'Laza',
            debugShowCheckedModeBanner: false,
            themeMode: themeNotifier.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SplashScreen(),
            // Use the global NavigatorKey
            navigatorKey: navigatorKey,
            // Use the global ScaffoldMessengerKey
            scaffoldMessengerKey: scaffoldMessengerKey,
            // Define your routes here
            routes: {
              '/order_confirmed_screen': (context) =>
                  const OrderConfirmedScreen(),
              '/sign-in-with-phone': (context) =>
                  const SignInWithPhoneNumber(), // Define the SignInWithPhoneNumber route
              '/notifications': (context) =>
                  NotificationsScreen(), // Define the NotificationsScreen route
              '/order_detail': (context) {
                final orderId =
                    ModalRoute.of(context)!.settings.arguments as String;
                return OrderDetailScreen(
                    orderId: orderId); // Define the OrderDetailScreen route
              },
            },
          );
        },
      ),
    );
  }
}
