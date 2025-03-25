import 'dart:convert'; // For JSON encoding
import 'dart:io'; // For Platform class
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; // Import http package
import 'package:laza/components/custom_appbar.dart';
import 'package:laza/components/custom_text_field.dart';
import 'package:laza/extensions/context_extension.dart';
import 'package:laza/reset_password/forgot_password_screen.dart';
import 'package:laza/components/bottom_nav_button.dart';
import 'package:laza/components/colors.dart';
import 'package:laza/sign_in_with_phone_number.dart'; // Import the SignInWithPhoneNumber screen

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool rememberMe = false;
  bool isLoading = false;
  final formKey = GlobalKey<FormState>();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final fullNameCtrl = TextEditingController();

  @override
  void dispose() {
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    emailCtrl.dispose();
    fullNameCtrl.dispose();
    super.dispose();
  }

  // Deployed API URL
  final String apiUrl =
      'https://pa-gebeya-backend.onrender.com/api/auth/register';

  // Function to show error messages
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Function to show success message
  void showSuccessMessage(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("User registered successfully!"),
        backgroundColor: Colors.green,
      ),
    );

    // Redirect to SignInWithPhoneNumber and pass phone number
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SignInWithPhoneNumber(initialPhoneNumber: phoneNumber),
      ),
      (Route<dynamic> route) => false,
    );
  }

  // Async function to handle the registration
  Future<void> registerUser() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final requestBody = {
      'fullName': fullNameCtrl.text,
      'phoneNumber': phoneCtrl.text,
      'email': emailCtrl.text,
      'password': passwordCtrl.text,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        showSuccessMessage(phoneCtrl.text); // Pass phone number
      } else {
        showErrorDialog(responseData['message'] ?? "Something went wrong");
      }
    } catch (error) {
      showErrorDialog(
          "Failed to register user. Please check your internet connection.");
    } finally {
      setState(() {
        isLoading = false;
      });
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
            label: isLoading ? 'Loading...' : 'Sign Up',
            onTap: isLoading ? null : registerUser,
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
                      Text('Welcome', style: context.headlineMedium),
                      Text(
                        'Please fill in your details to continue',
                        style: context.bodyMedium
                            ?.copyWith(color: ColorConstant.manatee),
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
                          CustomTextField(
                            controller: fullNameCtrl,
                            labelText: 'Full Name',
                            keyboardType: TextInputType.text,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Field is required'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: emailCtrl,
                            labelText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Field is required';
                              }
                              // Validate email format
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(val)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: phoneCtrl,
                            labelText: 'Phone Number',
                            keyboardType: TextInputType.phone,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Field is required';
                              }
                              // Validate phone number format (10 digits)
                              if (!RegExp(r'^[0-9]{10}$').hasMatch(val)) {
                                return 'Enter a valid 10-digit phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: passwordCtrl,
                            labelText: 'Password',
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Field is required';
                              }
                              // Validate password length (minimum 8 characters)
                              if (val.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
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
                                'By connecting your account you confirm that you agree with our',
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
