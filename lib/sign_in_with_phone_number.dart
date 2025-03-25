import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laza/components/custom_appbar.dart';
import 'package:laza/components/custom_text_field.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/reset_password/forgot_password_screen.dart';
import 'package:laza/otp_verification_screen.dart';
import 'package:http/http.dart' as http;
import 'package:laza/sign_in_screen.dart';
import 'components/bottom_nav_button.dart';
import 'components/colors.dart';

class SignInWithPhoneNumber extends StatefulWidget {
  final String? initialPhoneNumber; // Accept phone number from sign-up

  const SignInWithPhoneNumber({super.key, this.initialPhoneNumber});

  @override
  State<SignInWithPhoneNumber> createState() => _SignInWithPhoneNumberState();
}

class _SignInWithPhoneNumberState extends State<SignInWithPhoneNumber> {
  bool rememberMe = false;
  final formKey = GlobalKey<FormState>();
  late TextEditingController phoneCtrl;

  @override
  void initState() {
    super.initState();
    phoneCtrl = TextEditingController(
        text: widget.initialPhoneNumber ?? ""); // Auto-fill phone number
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    super.dispose();
  }

  // Function to send OTP
  Future<void> sendOtp() async {
    if (!formKey.currentState!.validate()) return;

    String phoneNumber = phoneCtrl.text.trim();

    try {
      final response = await http.post(
        Uri.parse('https://pa-gebeya-backend.onrender.com/api/auth/login'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phoneNumber': phoneNumber, // Corrected field name
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['message'] == 'OTP sent to email') {
          // Success confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP sent successfully to $phoneNumber'),
              backgroundColor: Colors.green, // Green background for success
            ),
          );
          // Navigate to OTP Verification Screen
          Navigator.pushNamed(
            context,
            '/otp_verification',
            arguments: phoneNumber,
          );
        } else {
          // If message is not as expected
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Unexpected response from the server')),
          );
        }
      } else {
        // Handle failure
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP')),
        );
      }
    } catch (e) {
      // Handle error (e.g., network error)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while sending OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: const CustomAppBar(),
          bottomNavigationBar: BottomNavButton(
            label: 'Send OTP',
            onTap: sendOtp,
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    children: [
                      Text(
                        'Welcome',
                        style: context.headlineMedium,
                      ),
                      const SizedBox(height: 20),
                      // Replace text with PA-Logos.png logo
                      Image.asset(
                        'assets/images/PA-Logos.png', // Ensure the correct path
                        height: 120, // Adjust height as needed
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Updated Header with larger and bold text
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'Enter your phone number to continue',
                              style: context.bodyMedium?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ColorConstant.manatee,
                              ),
                            ),
                          ),
                          CustomTextField(
                            controller: phoneCtrl,
                            labelText: 'Phone Number',
                            keyboardType: TextInputType.phone,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Field is required'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen()),
                              ),
                              child: const Text('Forget Password?',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile.adaptive(
                            activeColor:
                                Platform.isIOS ? ColorConstant.primary : null,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Remember me'),
                            value: rememberMe,
                            onChanged: (val) =>
                                setState(() => rememberMe = val),
                          ),
                          const SizedBox(height: 20),
                          // Add "Don't have an account? Sign Up" link
                          TextButton(
                            onPressed: () {
                              // Navigate to the sign-up screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInScreen(),
                                ),
                              );
                            },
                            child: Text.rich(
                              TextSpan(
                                text: "Don't have an account? ",
                                style: context.bodyMedium?.copyWith(
                                  color: ColorConstant.manatee,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: context.bodyMedium?.copyWith(
                                      color: ColorConstant.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 8.0),
                    child: InkWell(
                      onTap: () {},
                      child: Ink(
                        child: Text.rich(
                          TextSpan(
                            text:
                                'By connecting your account, you agree with our',
                            style: context.bodySmall
                                ?.copyWith(color: ColorConstant.manatee),
                            children: [
                              TextSpan(
                                  text: ' Terms and Conditions',
                                  style: context.bodySmallW500),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
