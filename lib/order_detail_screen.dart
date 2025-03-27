import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final DateTime orderCreationTime; // Required parameter

  const OrderDetailScreen({
    required this.orderId,
    required this.orderCreationTime,
  });

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  dynamic orderData;
  bool isLoading = true;
  String errorMessage = '';
  Timer? _countdownTimer;
  int _remainingTime = 600;
  bool _isCancellable = true;

  @override
  void initState() {
    super.initState();
    _initializeCountdown();
    fetchOrderDetails();
  }

  Future<void> _initializeCountdown() async {
    await _loadCountdownState();
    _startCountdown();
  }

  Future<void> _loadCountdownState() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final elapsed = now.difference(widget.orderCreationTime).inSeconds;

    setState(() {
      _remainingTime = 600 - elapsed > 0 ? 600 - elapsed : 0;
      _isCancellable = _remainingTime > 0;
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          _isCancellable = false;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchOrderDetails() async {
    final String url =
        'https://pa-gebeya-backend.onrender.com/api/orders/${widget.orderId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orderData = data;
          isLoading = false;

          if (orderData['status']?.toLowerCase() == 'cancelled' ||
              orderData['status']?.toLowerCase() == 'delivered') {
            _isCancellable = false;
          }
        });
      } else if (response.statusCode == 404) {
        setState(() {
          isLoading = false;
          errorMessage = 'This order is no longer available.';
          _isCancellable = false;
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

  Future<void> _cancelOrder() async {
    if (!_isCancellable) return;

    try {
      final response = await http.delete(
        Uri.parse(
            'https://pa-gebeya-backend.onrender.com/api/orders/${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isCancellable = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        fetchOrderDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling order: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _refreshOrderDetails() {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    fetchOrderDetails();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
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
        return Theme.of(context).textTheme.bodyMedium!.color!;
    }
  }

  TextStyle _getStatusValueStyle(String status) {
    return TextStyle(
      fontSize: 16,
      color: _getStatusColor(status),
      fontWeight: FontWeight.bold,
    );
  }

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
                : Stack(
                    children: [
                      SingleChildScrollView(
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
                                    orderData['paymentImage'],
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          orderData['paymentImage'],
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
                                        itemCount:
                                            orderData['orderDetails'].length,
                                        itemBuilder: (context, index) {
                                          final product =
                                              orderData['orderDetails'][index];
                                          return ListTile(
                                            leading: product['productImage'] !=
                                                    null
                                                ? Image.network(
                                                    product['productImage'],
                                                    width: 50,
                                                    height: 50,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Icon(
                                                        Icons.error,
                                                        color:
                                                            colorScheme.error,
                                                      );
                                                    },
                                                  )
                                                : Icon(
                                                    Icons.image_not_supported,
                                                    color:
                                                        colorScheme.secondary,
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
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          children: [
                            if (_isCancellable)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.timer,
                                        color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Time to cancel: ${_formatTime(_remainingTime)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _isCancellable ? _cancelOrder : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isCancellable ? Colors.red : Colors.grey,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cancel,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isCancellable
                                        ? 'Cancel Order'
                                        : 'Cancellation Period Expired',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
