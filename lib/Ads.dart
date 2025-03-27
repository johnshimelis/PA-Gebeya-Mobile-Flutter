import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Ads extends StatefulWidget {
  const Ads({super.key});

  @override
  _AdsState createState() => _AdsState();
}

class _AdsState extends State<Ads> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  List<String> _adImages = [];
  bool _isLoading = true;
  bool _hasError = false;
  final String _adsCacheKey = 'cached_ads';
  final String _apiUrl = "https://pa-gebeya-backend.onrender.com/api/ads/ads";

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _loadAdsWithCacheFirst(); // Changed to cache-first approach
  }

  Future<void> _loadAdsWithCacheFirst() async {
    // 1. First try to load from cache immediately
    final cachedAds = await _getCachedAds();
    if (cachedAds != null && cachedAds.isNotEmpty) {
      if (mounted) {
        setState(() {
          _adImages = cachedAds;
          _isLoading = false;
        });
        _startAutoScroll();
      }
    }

    // 2. Then try to fetch from network in background
    try {
      final freshAds = await _fetchAdsFromNetwork();
      await _cacheAds(freshAds);

      // Only update if the new data is different
      if (mounted && !_areListsEqual(freshAds, _adImages)) {
        setState(() {
          _adImages = freshAds;
          _hasError = false;
        });
        _startAutoScroll();
      }
    } catch (e) {
      debugPrint("❌ Network error: $e");
      if (mounted && _adImages.isEmpty) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  Future<List<String>> _fetchAdsFromNetwork() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint("🟢 Fetched ${data.length} ads from network");

        return data
            .expand((ad) => (ad["images"] as List)
                .map((img) => img.toString())
                .where((url) => url.isNotEmpty))
            .toList();
      } else {
        throw Exception("Failed to load ads: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching ads: $e");
      rethrow;
    }
  }

  Future<List<String>?> _getCachedAds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_adsCacheKey);
      if (cachedData == null) return null;
      return (jsonDecode(cachedData) as List).cast<String>();
    } catch (e) {
      debugPrint("❌ Error reading cached ads: $e");
      return null;
    }
  }

  Future<void> _cacheAds(List<String> ads) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_adsCacheKey, jsonEncode(ads));
      debugPrint("✅ Cached ${ads.length} ads");
    } catch (e) {
      debugPrint("❌ Error caching ads: $e");
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_adImages.length <= 1) return;

    _autoScrollTimer =
        Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients && mounted) {
        final nextPage = (_currentPage + 1) % _adImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _refreshAds() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    await _loadAdsWithCacheFirst();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading && _adImages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _adImages.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Failed to load ads", style: TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _refreshAds,
            child: const Text("Retry"),
          ),
        ],
      );
    }

    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _adImages.length,
        onPageChanged: (page) {
          if (mounted) {
            setState(() {
              _currentPage = page;
            });
          }
        },
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: CachedNetworkImage(
                imageUrl: _adImages[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child:
                        Icon(Icons.broken_image, size: 50, color: Colors.red),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
