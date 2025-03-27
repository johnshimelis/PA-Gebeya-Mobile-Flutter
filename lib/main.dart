import 'package:flutter/material.dart';
import 'package:laza/splash_screen.dart';
import 'package:laza/theme.dart';
import 'package:provider/provider.dart';
import 'package:laza/order_confirmed_screen.dart';
import 'package:laza/sign_in_with_phone_number.dart';
import 'package:laza/notifications.dart';
import 'package:laza/order_detail_screen.dart';
import 'package:laza/home_screen.dart';
import 'package:laza/dashboard.dart';
import 'package:laza/otp_verification_screen.dart';

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
            title: 'PA Gebeya',
            debugShowCheckedModeBanner: false,
            themeMode: themeNotifier.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SplashScreen(),
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: scaffoldMessengerKey,
            routes: {
              '/home': (context) => const HomeScreen(),
              '/order_confirmed_screen': (context) =>
                  const OrderConfirmedScreen(),
              '/sign_in_with_phone_number': (context) =>
                  const SignInWithPhoneNumber(),
              '/notifications': (context) =>
                  NotificationsScreen(onNotificationUpdated: () {}),
              '/order_detail': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map;
                return OrderDetailScreen(
                  orderId: args['orderId'],
                  orderCreationTime: args['createdAt'] ?? DateTime.now(),
                );
              },
              '/dashboard': (context) => const Dashboard(),
              '/otp_verification': (context) {
                final phoneNumber =
                    ModalRoute.of(context)!.settings.arguments as String;
                return OtpVerificationScreen(phoneNumber: phoneNumber);
              },
            },
          );
        },
      ),
    );
  }
}
