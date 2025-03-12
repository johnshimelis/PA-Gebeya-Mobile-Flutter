import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  OrderDetailScreen({required this.orderId});

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
      } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID
                      Text(
                        'Order ID: ${orderData['id'] ?? 'N/A'}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),

                      // Order Status
                      Text(
                        'Status: ${orderData['status'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),

                      // Total Amount
                      Text(
                        'Total: \$${orderData['amount']?.toStringAsFixed(2) ?? 'N/A'}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),

                      // Order Date
                      Text(
                        'Date: ${orderData['createdAt'] != null ? DateTime.parse(orderData['createdAt']).toLocal().toString() : 'N/A'}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),

                      // Delivery Address
                      Text(
                        'Delivery Address: ${orderData['deliveryAddress'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),

                      // Phone Number
                      Text(
                        'Phone Number: ${orderData['phoneNumber'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),

                      // Payment Image
                      if (orderData['paymentImage'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Image:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Image.network(
                              'https://pa-gebeya-backend.onrender.com${orderData['paymentImage']}',
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text('Failed to load image');
                              },
                            ),
                          ],
                        ),
                      SizedBox(height: 16),

                      // Products List
                      Text(
                        'Products:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),

                      if (orderData['orderDetails'] != null &&
                          orderData['orderDetails'].isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: orderData['orderDetails'].length,
                            itemBuilder: (context, index) {
                              final product = orderData['orderDetails'][index];
                              return ListTile(
                                leading: product['productImage'] != null
                                    ? Image.network(
                                        'https://pa-gebeya-backend.onrender.com${product['productImage']}',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(Icons
                                              .error); // Fallback for failed image load
                                        },
                                      )
                                    : Icon(Icons
                                        .image_not_supported), // Fallback for missing image
                                title: Text(product['product'] ?? 'N/A'),
                                subtitle: Text(
                                  'Quantity: ${product['quantity'] ?? 'N/A'}, Price: \$${product['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Text('No products found.'),
                    ],
                  ),
                ),
    );
  }
}
