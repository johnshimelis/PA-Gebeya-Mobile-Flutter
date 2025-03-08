import 'package:flutter/material.dart';
import 'dart:async'; // For Timer

class Foryouads extends StatefulWidget {
  const Foryouads({super.key});

  @override
  _DiscountAdsState createState() => _DiscountAdsState();
}

class _DiscountAdsState extends State<Foryouads> {
  final List<String> discountAdImages = [
    'assets/images/foryou.jpeg',
    'assets/images/foryou.jpg',
    'assets/images/foryou1.jpg',
    'assets/images/foryou2.jpeg',
    'assets/images/discount5.webp',
  ];

  late PageController _controller;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
    _autoScroll();
  }

  void _autoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < discountAdImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: PageView.builder(
        controller: _controller,
        itemCount: discountAdImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 8.0,
              right: index == discountAdImages.length - 1 ? 0 : 8.0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Image.asset(
                discountAdImages[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
      ),
    );
  }
}
