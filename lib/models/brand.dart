import 'package:flutter/material.dart';

class Brand {
  final String name;
  final IconData iconData;
  final String categoryId; // Added categoryId

  const Brand(this.name, this.iconData, {required this.categoryId});
}
