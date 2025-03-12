import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/dashboard.dart';
import 'package:laza/intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay for 5 seconds before navigating to the IntroductionScreen
    Future.delayed(const Duration(seconds: 5))
        .then((value) => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.red, // Set status bar color to red
        systemNavigationBarColor: Colors.red, // Set navigation bar color to red
        statusBarIconBrightness: Brightness.light, // Light icons for status bar
      ),
      child: Scaffold(
        backgroundColor: Colors.red, // Set background color to red
        body: Center(
          child: Image.asset(
            'assets/images/PA-Logos.png', // Load PA-Logos.png
            width: 150, // Set a smaller width for the image
            height: 150, // Set a smaller height for the image
          ),
        ),
      ),
    );
  }
}
