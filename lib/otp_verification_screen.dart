import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  Map<String, dynamic>? userData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('userData');

    if (userJson != null) {
      Map<String, dynamic> loadedUserData = json.decode(userJson);

      // Ensure the user ID and token exist before proceeding
      if (loadedUserData.containsKey('userId') &&
          loadedUserData.containsKey('token')) {
        setState(() {
          userData = loadedUserData;
        });
        debugPrint("✅ User data loaded: $userData");

        // Check if token is expired
        if (_isTokenExpired(userData!['token'])) {
          await logoutUser();
          debugPrint("🚨 User token expired. Please log in again.");
        }
      } else {
        debugPrint("⚠ Invalid user data: Missing userId or token.");
      }
    } else {
      debugPrint("⚠ No user data found in SharedPreferences.");
    }
  }

  // Check if the token has expired
  bool _isTokenExpired(String token) {
    try {
      final payload = _decodeJwt(token);
      if (payload['exp'] == null) {
        debugPrint("❌ Token does not contain an expiration field.");
        return true; // Assume expired if no expiration field
      }

      final expTimestamp = payload['exp'] * 1000; // Convert to milliseconds
      final expirationDate =
          DateTime.fromMillisecondsSinceEpoch(expTimestamp, isUtc: true);
      final now = DateTime.now().toUtc();

      debugPrint('🕒 Token Expiration Time (UTC): $expirationDate');
      debugPrint('🕒 Current Time (UTC): $now');

      bool isExpired = now.isAfter(expirationDate);
      debugPrint('🚨 Token Expired? $isExpired');

      return isExpired;
    } catch (e) {
      debugPrint("❌ Error decoding token: $e");
      return true; // Assume expired if there's an error
    }
  }

  // Decode JWT token
  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception("Invalid JWT structure");

      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      final decodedPayload = utf8.decode(payload);

      return json.decode(decodedPayload);
    } catch (e) {
      debugPrint("❌ JWT Decoding Error: $e");
      throw Exception("Failed to decode JWT");
    }
  }

  Future<void> verifyOtp() async {
    String otp = otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP! Enter a 6-digit code.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://pa-gebeya-backend.onrender.com/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': widget.phoneNumber, 'otp': otp}),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 &&
          responseBody['message'] == 'Login successful') {
        Map<String, dynamic> user = {
          'userId': responseBody['user']['userId'],
          'fullName': responseBody['user']['fullName'],
          'email': responseBody['user']['email'],
          'phoneNumber': responseBody['user']['phoneNumber'],
          'token': responseBody['token'],
        };

        // Save user data to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', json.encode(user));
        await prefs.setString(
            'userId', user['userId']); // Save userId separately
        await prefs.setString(
            'token', responseBody['token']); // Save token separately
        await prefs.reload(); // Reload to ensure data is updated

        debugPrint("✅ User logged in successfully: $user");
        debugPrint("✅ Stored userId: ${prefs.getString('userId')}");
        debugPrint("✅ Stored token: ${prefs.getString('token')}");
        debugPrint("✅ Stored fullName: ${user['fullName']}");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP Verified Successfully!')),
        );

        // Navigate to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verification failed!')),
        );
      }
    } catch (e) {
      debugPrint("❌ Error verifying OTP: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while verifying OTP.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Logout user and clear user data
  Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    await prefs.remove('userId');

    setState(() {
      userData = null;
    });

    debugPrint("🚪 User logged out!");
    Navigator.pushReplacementNamed(context, '/sign_in_with_phone_number');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Enter the 6-digit OTP sent to ${widget.phoneNumber}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Verify OTP"),
            ),
            const SizedBox(height: 30),
            if (userData != null) ...[],
          ],
        ),
      ),
    );
  }
}
