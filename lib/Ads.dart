import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class Ads extends StatefulWidget {
  const Ads({super.key});

  @override
  _AdsState createState() => _AdsState();
}

class _AdsState extends State<Ads> {
  late PageController _controller;
  int _currentPage = 0;
  Timer? _timer;
  List<String> adImages = [];
  bool isLoading = true;
  bool hasError = false;

  final String baseUrl = "https://pa-gebeya-backend.onrender.com/";

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
    fetchAds();
  }

  /// Fetch Ads from Backend
  Future<void> fetchAds() async {
    const String apiUrl = "https://pa-gebeya-backend.onrender.com/api/ads/ads";

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("Request timed out");
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          setState(() {
            adImages = data
                .expand((ad) => (ad["images"] as List).map(
                    (img) => img.toString().isNotEmpty ? "$baseUrl$img" : ""))
                .where((url) => url.isNotEmpty) // Remove empty URLs
                .toList();
            isLoading = false;
            hasError = false;
          });

          if (adImages.isNotEmpty) _autoScroll();
        } else {
          setState(() {
            isLoading = false;
            hasError = true;
          });
        }
      } else {
        throw Exception("Failed to load ads");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print("Error fetching ads: $error");
    }
  }

  /// Auto-scroll Ads
  void _autoScroll() {
    _timer?.cancel(); // Clear any existing timers
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_controller.hasClients) {
        _currentPage = (_currentPage + 1) % adImages.length;
        _controller.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError || adImages.isEmpty) {
      return const Center(
          child:
              Text("Failed to load ads", style: TextStyle(color: Colors.red)));
    }

    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _controller,
        itemCount: adImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: CachedNetworkImage(
                imageUrl: adImages[index],
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) {
                  return const Center(
                    child:
                        Icon(Icons.broken_image, size: 50, color: Colors.red),
                  );
                },
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
