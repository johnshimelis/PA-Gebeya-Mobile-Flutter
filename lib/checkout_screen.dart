import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File class
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:path_provider/path_provider.dart'; // For downloading images
import 'package:laza/order_confirmed_screen.dart'; // Import your order confirmed screen
import 'package:laza/loading_screen.dart'; // Import the LoadingScreen
import 'package:laza/main.dart'; // Import the global keys

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<dynamic> cartItems = [];
  double totalAmount = 0.0;
  String? selectedFile;
  String? userId;
  String? name;

  @override
  void initState() {
    super.initState();
    loadCartData();
  }

  Future<File> downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    final documentDirectory = await getTemporaryDirectory();
    final file = File(
        '${documentDirectory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    file.writeAsBytesSync(response.bodyBytes);
    return file;
  }

  // Load cart data from SharedPreferences
  Future<void> loadCartData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? checkoutDataString = prefs.getString('checkoutData');

    if (checkoutDataString != null) {
      Map<String, dynamic> checkoutData = jsonDecode(checkoutDataString);
      setState(() {
        cartItems = checkoutData['orderDetails'];
        totalAmount = double.parse(checkoutData['amount']);
        userId = checkoutData['userId']; // Load userId
        name = checkoutData['fullName']; // Load fullName
      });
    }
  }

  // Function to pick a file using ImagePicker
  Future<void> pickFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          selectedFile =
              image.path; // Use the full file path, not just the name
        });
      } else {
        // User canceled the picker
        setState(() {
          selectedFile = null;
        });
      }
    } catch (e) {
      print("Error picking file: $e");
    }
  }

  // Show the complete order modal
  void _showCompleteOrderModal(BuildContext context) {
    // Controllers for the text fields
    final TextEditingController phoneNumberController = TextEditingController();
    final TextEditingController deliveryLocationController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delivery Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                // Phone Number Field
                TextField(
                  controller: phoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.phone,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  keyboardType: TextInputType.phone,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 20),

                // Delivery Location Field
                TextField(
                  controller: deliveryLocationController,
                  decoration: InputDecoration(
                    labelText: 'Delivery Location',
                    labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.location_on,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  keyboardType: TextInputType.text,
                  maxLines: 3, // Increased height
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 20),

                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cancel Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the modal
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),

                    // Confirm Button
                    ElevatedButton(
                      onPressed: () async {
                        final String phoneNumber = phoneNumberController.text;
                        final String deliveryLocation =
                            deliveryLocationController.text;

                        if (phoneNumber.isEmpty || deliveryLocation.isEmpty) {
                          // Show an error message if fields are empty
                          scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all fields!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          // Dismiss the modal immediately
                          Navigator.of(context).pop();

                          // Show the loading screen
                          navigatorKey.currentState?.push(
                            MaterialPageRoute(
                              builder: (context) => const LoadingScreen(),
                            ),
                          );

                          // Retrieve the existing checkout data from SharedPreferences
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String? checkoutDataString =
                              prefs.getString('checkoutData');

                          if (checkoutDataString != null) {
                            Map<String, dynamic> checkoutData =
                                jsonDecode(checkoutDataString);

                            // Update the checkout data with the new fields
                            checkoutData['phoneNumber'] = phoneNumber;
                            checkoutData['deliveryAddress'] = deliveryLocation;
                            checkoutData['paymentImage'] = selectedFile != null
                                ? selectedFile!
                                : "/uploads/default-payment.png"; // Fallback if no image is selected

                            // Ensure required fields are not null
                            checkoutData['userId'] =
                                checkoutData['userId'] ?? "Unknown ID";
                            checkoutData['name'] = checkoutData['fullName'] ??
                                "Unknown"; // Use fullName
                            checkoutData['amount'] =
                                checkoutData['amount'] ?? 0;
                            checkoutData['status'] =
                                checkoutData['status'] ?? "Pending";

                            // Ensure orderDetails fields are not null
                            checkoutData['orderDetails'] =
                                (checkoutData['orderDetails'] as List)
                                    .map((item) {
                              return {
                                'productId':
                                    item['productId'] ?? "Unknown Product ID",
                                'product': item['product'] ?? "Unknown Product",
                                'quantity': item['quantity'] ?? 1,
                                'price': item['price'] ?? 0,
                                'productImage':
                                    item['productImage'] ?? "placeholder.jpg",
                              };
                            }).toList();

                            // Save the updated checkout data back to SharedPreferences
                            prefs.setString(
                                'checkoutData', jsonEncode(checkoutData));

                            // Log the updated data in the debug console
                            debugPrint(jsonEncode(checkoutData));

                            // Send the order data to the API
                            try {
                              // Create a multipart request
                              var request = http.MultipartRequest(
                                'POST',
                                Uri.parse(
                                    'https://pa-gebeya-backend.onrender.com/api/orders'),
                              );

                              // Add text fields
                              request.fields['userId'] =
                                  checkoutData['userId'].toString();
                              request.fields['name'] = checkoutData['name'];
                              request.fields['amount'] =
                                  checkoutData['amount'].toString();
                              request.fields['status'] = checkoutData['status'];
                              request.fields['phoneNumber'] = phoneNumber;
                              request.fields['deliveryAddress'] =
                                  deliveryLocation;
                              request.fields['orderDetails'] =
                                  jsonEncode(checkoutData['orderDetails']);

                              // Add payment image file
                              if (selectedFile != null &&
                                  File(selectedFile!).existsSync()) {
                                var paymentImageFile =
                                    await http.MultipartFile.fromPath(
                                  'paymentImage',
                                  selectedFile!,
                                );
                                request.files.add(paymentImageFile);
                              } else {
                                print(
                                    "Payment image file not found or invalid: $selectedFile");
                              }

                              // Add product image files
                              for (var item in checkoutData['orderDetails']) {
                                if (item['productImage'] != null &&
                                    item['productImage'] != "placeholder.jpg") {
                                  // Download the remote image
                                  final imageFile =
                                      await downloadImage(item['productImage']);

                                  // Attach the downloaded image to the request
                                  var productImageFile =
                                      await http.MultipartFile.fromPath(
                                    'productImages', // Use the same field name as in the web version
                                    imageFile.path,
                                  );
                                  request.files.add(productImageFile);
                                }
                              }

                              // Send the request
                              var response = await request.send();

                              // Log the response status code and body
                              print(
                                  'Response Status Code: ${response.statusCode}');
                              final responseBody =
                                  await response.stream.bytesToString();
                              print('Response Body: $responseBody');

                              if (response.statusCode == 200 ||
                                  response.statusCode == 201) {
                                // Parse the response to get the order ID
                                final responseData = jsonDecode(responseBody);
                                final String orderId =
                                    responseData['id'].toString();

                                // Show a success message

                                // Wait for 2 seconds before clearing the cart
                                await Future.delayed(
                                    const Duration(seconds: 2));

                                // Clear the cart for the specific userId
                                final String userId =
                                    checkoutData['userId'].toString();
                                final String? userToken =
                                    prefs.getString('token');

                                if (userToken == null) {
                                  scaffoldMessengerKey.currentState
                                      ?.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Authentication token is missing. Please log in again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final clearCartResponse = await http.delete(
                                  Uri.parse(
                                      'https://pa-gebeya-backend.onrender.com/api/cart/user/$userId'),
                                  headers: {
                                    'Authorization': 'Bearer $userToken',
                                  },
                                );

                                // Log the cart-clearing response
                                print(
                                    'Cart Clearing Response Status Code: ${clearCartResponse.statusCode}');
                                print(
                                    'Cart Clearing Response Body: ${clearCartResponse.body}');

                                if (clearCartResponse.statusCode == 200) {
                                  print(
                                      "Cart cleared successfully for user: $userId");
                                } else {
                                  print(
                                      "Failed to clear cart for user: $userId");
                                }

                                // Clear the checkout data from SharedPreferences
                                await prefs.remove('checkoutData');

                                // ✅ Send notification
                                print(
                                    "🔔 Sending order notification to the user...");
                                final notificationResponse = await http.post(
                                  Uri.parse(
                                      'https://pa-gebeya-backend.onrender.com/api/users/notifications'),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer $userToken',
                                  },
                                  body: jsonEncode({
                                    'userId': userId,
                                    'orderId': orderId,
                                    'message':
                                        'Hello ${checkoutData['name']}, your <a href="/view-detail" class="order-link">order</a> is submitted successfully and pending. Please wait for approval.',
                                    'date': DateTime.now().toIso8601String(),
                                  }),
                                );

                                if (notificationResponse.statusCode == 200) {
                                  print("✅ Notification sent successfully!");
                                } else {
                                  print(
                                      "❌ Failed to send notification: ${notificationResponse.body}");
                                }

                                // ✅ Save order in UserOrders
                                print("📦 Sending order data to UserOrders...");
                                final userOrderResponse = await http.post(
                                  Uri.parse(
                                      'https://pa-gebeya-backend.onrender.com/api/users/orders'),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer $userToken',
                                  },
                                  body: jsonEncode({
                                    'orderId': orderId,
                                    'userId': userId,
                                    'date': DateTime.now().toIso8601String(),
                                    'status': 'Pending',
                                    'total': checkoutData['amount'] ?? 0,
                                  }),
                                );

                                if (userOrderResponse.statusCode == 200) {
                                  print(
                                      "✅ Order successfully saved in UserOrders!");
                                } else {
                                  print(
                                      "❌ Failed to save order in UserOrders: ${userOrderResponse.body}");
                                }

                                // Navigate to the order confirmed screen with lazy loading
                                navigatorKey.currentState?.pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const OrderConfirmedScreen(),
                                  ),
                                );
                              } else {
                                // Show an error message
                                scaffoldMessengerKey.currentState?.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Failed to submit order. Please try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );

                                // Go back to the checkout screen
                                navigatorKey.currentState?.pop();
                              }
                            } catch (e) {
                              // Show an error message
                              scaffoldMessengerKey.currentState?.showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );

                              // Go back to the checkout screen
                              navigatorKey.currentState?.pop();
                            }
                          } else {
                            // Handle the case where checkout data is not found
                            scaffoldMessengerKey.currentState?.showSnackBar(
                              const SnackBar(
                                content: Text('Checkout data not found!'),
                                backgroundColor: Colors.red,
                              ),
                            );

                            // Go back to the checkout screen
                            navigatorKey.currentState?.pop();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Total: \$${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bank Account Details
            Text(
              'Bank Account Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),

            // Bank of Ethiopia Card
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank of Ethiopia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Account Number: 1000522957273',
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Account Name: John Doe',
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Chase Bank Card
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chase Bank',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Account Number: 9876543210987654',
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Account Name: Jane Smith',
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Wells Fargo Card
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wells Fargo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Account Number: 4567890123456789',
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Account Name: Robert Johnson',
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Upload Payment Screenshot (Centered)
            Center(
              child: Column(
                children: [
                  Text(
                    'Upload Payment Screenshot',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: pickFile, // Use the pickFile function
                    icon: Icon(Icons.upload,
                        color: Theme.of(context).colorScheme.primary),
                    label: Text(
                      'Choose File',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  if (selectedFile != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Selected File: $selectedFile',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Complete Order Button
            Center(
              child: ElevatedButton(
                onPressed: () => _showCompleteOrderModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                child: Text(
                  'Complete Order',
                  style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: 20), // Added extra space at the bottom
          ],
        ),
      ),
    );
  }
}
