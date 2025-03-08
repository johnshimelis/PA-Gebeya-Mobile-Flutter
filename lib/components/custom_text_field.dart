import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final String? Function(String?) validator;
  final bool obscureText; // Add this line
  final TextInputAction? textInputAction; // Add this line

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.keyboardType,
    required this.validator,
    this.obscureText = false, // Default to false if not provided
    this.textInputAction, // Add this line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText, // Use this in the TextFormField
      validator: validator,
      textInputAction: textInputAction, // Use the textInputAction here
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
