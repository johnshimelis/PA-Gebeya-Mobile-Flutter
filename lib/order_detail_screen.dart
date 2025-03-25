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
        return Theme.of(context).textTheme.bodyMedium!.color!; // Updated here
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: colorScheme.primary,
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
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.background,
            ],
          ),
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Order Details...',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.primary,
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
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (errorMessage !=
                            'This order is no longer available.')
                          ElevatedButton(
                            onPressed: _refreshOrderDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style: TextStyle(color: colorScheme.onPrimary),
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_turned_in,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Status: ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
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
                                    Icon(
                                      Icons.attach_money,
                                      color: colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Total: \$${orderData['amount']?.toStringAsFixed(2) ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Date: ${orderData['createdAt'] != null ? DateTime.parse(orderData['createdAt']).toLocal().toString() : 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delivery Address: ${orderData['deliveryAddress'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      color: colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Phone Number: ${orderData['phoneNumber'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
                                      ),
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
                                orderData[
                                    'paymentImage'], // Use the full URL directly
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
                                    Text(
                                      'Payment Image:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Image.network(
                                      orderData[
                                          'paymentImage'], // Use the full URL directly
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Text(
                                          'Failed to load image',
                                          style: TextStyle(
                                            color: colorScheme.error,
                                          ),
                                        );
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
                                Text(
                                  'Products:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
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
                                                product[
                                                    'productImage'], // Use the full URL directly
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Icon(
                                                    Icons.error,
                                                    color: colorScheme.error,
                                                  );
                                                },
                                              )
                                            : Icon(
                                                Icons.image_not_supported,
                                                color: colorScheme.secondary,
                                              ),
                                        title: Text(
                                          product['product'] ?? 'N/A',
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Quantity: ${product['quantity'] ?? 'N/A'}, Price: \$${product['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                else
                                  Text(
                                    'No products found.',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
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
    );
  }
}
