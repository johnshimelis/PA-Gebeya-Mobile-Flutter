import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({required this.orderId});

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  dynamic orderData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    final String url =
        'https://pa-gebeya-backend.onrender.com/api/orders/${widget.orderId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data"); // Debugging: Print the API response

        setState(() {
          orderData = data;
          isLoading = false;
        });

        // Debugging: Print image URLs
        if (orderData['paymentImage'] != null) {
          print("Payment Image URL: ${orderData['paymentImage']}");
        }
        if (orderData['orderDetails'] != null) {
          for (var product in orderData['orderDetails']) {
            if (product['productImage'] != null) {
              print("Product Image URL: ${product['productImage']}");
            }
          }
        }
      } else if (response.statusCode == 404) {
        // Handle the case where the order is not found
        setState(() {
          isLoading = false;
          errorMessage = 'This order is no longer available.';
        });
      } else {
        // Handle other errors
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load order details: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = 'An error occurred: $error';
      });
    }
  }

  void _refreshOrderDetails() {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    fetchOrderDetails();
  }

  // Helper function to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber; // Darker yellow for better visibility
      case 'cancelled':
      case 'un-paid':
        return Colors.red;
      case 'approved':
      case 'delivered':
      case 'paid':
        return Colors.green;
      case 'processing':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  // Helper function to get status text style
  TextStyle _getStatusValueStyle(String status) {
    return TextStyle(
      fontSize: 16,
      color: _getStatusColor(status),
      fontWeight: FontWeight.bold, // Make the status value bold
    );
  }

  // Function to show payment image in full screen
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Payment Image'),
          ),
          body: Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrderDetails,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent.withOpacity(0.1), Colors.white],
          ),
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading Order Details...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (errorMessage !=
                            'This order is no longer available.')
                          ElevatedButton(
                            onPressed: _refreshOrderDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order ID: ${orderData['id'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.assignment_turned_in,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Status: ',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors
                                            .black, // Keep the label black
                                      ),
                                    ),
                                    Text(
                                      '${orderData['status'] ?? 'N/A'}',
                                      style: _getStatusValueStyle(
                                          orderData['status'] ?? 'N/A'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_money,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Total: \$${orderData['amount']?.toStringAsFixed(2) ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Date: ${orderData['createdAt'] != null ? DateTime.parse(orderData['createdAt']).toLocal().toString() : 'N/A'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delivery Address: ${orderData['deliveryAddress'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Phone Number: ${orderData['phoneNumber'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (orderData['paymentImage'] != null)
                          GestureDetector(
                            onTap: () {
                              _showFullScreenImage(
                                context,
                                'https://pa-gebeya-backend.onrender.com${orderData['paymentImage']}',
                              );
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Payment Image:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Image.network(
                                      'https://pa-gebeya-backend.onrender.com${orderData['paymentImage']}',
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Text(
                                            'Failed to load image');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Products:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (orderData['orderDetails'] != null &&
                                    orderData['orderDetails'].isNotEmpty)
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: orderData['orderDetails'].length,
                                    itemBuilder: (context, index) {
                                      final product =
                                          orderData['orderDetails'][index];
                                      return ListTile(
                                        leading: product['productImage'] != null
                                            ? Image.network(
                                                'https://pa-gebeya-backend.onrender.com${product['productImage']}',
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Icon(
                                                      Icons.error);
                                                },
                                              )
                                            : const Icon(
                                                Icons.image_not_supported),
                                        title:
                                            Text(product['product'] ?? 'N/A'),
                                        subtitle: Text(
                                          'Quantity: ${product['quantity'] ?? 'N/A'}, Price: \$${product['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                        ),
                                      );
                                    },
                                  )
                                else
                                  const Text('No products found.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
