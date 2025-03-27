import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_detail_screen.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback onOrderUpdated;

  const OrdersScreen({super.key, required this.onOrderUpdated});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final String? userId = prefs.getString('userId');

    if (token == null || userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://pa-gebeya-backend.onrender.com/api/users/orders/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> userOrders = json.decode(response.body)['orders'];
        final List<dynamic> fetchedOrders = [];

        for (var order in userOrders) {
          final orderResponse = await http.get(
            Uri.parse(
                'https://pa-gebeya-backend.onrender.com/api/orders/${order['orderId']}'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          );

          if (orderResponse.statusCode == 200) {
            final orderDetails = json.decode(orderResponse.body);
            fetchedOrders.add({
              ...order,
              'status': orderDetails['status'],
              'createdAt':
                  orderDetails['createdAt'], // Add createdAt from details
            });
          } else {
            fetchedOrders.add(order);
          }
        }

        setState(() {
          orders = fetchedOrders;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching orders: $error');
    }
  }

  Future<void> handleDelete(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse(
            'https://pa-gebeya-backend.onrender.com/api/users/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          orders =
              orders.where((order) => order['orderId'] != orderId).toList();
        });
        widget.onOrderUpdated();
      }
    } catch (error) {
      print('Error deleting order: $error');
    }
  }

  void handleViewDetails(dynamic order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          orderId: order['orderId'],
          orderCreationTime:
              DateTime.parse(order['createdAt']), // Pass creation time
        ),
      ),
    ).then((_) {
      // Refresh orders when returning from detail screen
      fetchOrders();
    });
  }

  TextStyle getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TextStyle(color: Colors.orange, fontWeight: FontWeight.bold);
      case 'cancelled':
      case 'un-paid':
        return TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
      case 'approved':
      case 'delivered':
      case 'paid':
        return TextStyle(color: Colors.green, fontWeight: FontWeight.bold);
      case 'processing':
        return TextStyle(color: Colors.grey, fontWeight: FontWeight.bold);
      default:
        return TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Orders',
          style: TextStyle(
            color: Theme.of(context).textTheme.headlineSmall?.color,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).iconTheme.color,
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : orders.isEmpty
              ? Center(
                  child: Text(
                    'No orders found.',
                    style: TextStyle(
                        fontSize: 16, color: Theme.of(context).hintColor),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        color: Theme.of(context).cardColor,
                        child: ListTile(
                          leading: Icon(Icons.shopping_bag,
                              color: Theme.of(context).primaryColor),
                          title: Text(
                            'Order #${order['orderId']}',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Status: ',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color),
                                    ),
                                    TextSpan(
                                      text: order['status'],
                                      style: getStatusStyle(order['status']),
                                    ),
                                  ],
                                ),
                              ),
                              if (order['createdAt'] != null)
                                Text(
                                  'Placed: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(order['createdAt']).toLocal())}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.visibility,
                                    color: Theme.of(context).iconTheme.color),
                                onPressed: () => handleViewDetails(order),
                              ),
                              if (order['status']?.toLowerCase() == 'pending')
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color:
                                          Theme.of(context).colorScheme.error),
                                  onPressed: () =>
                                      handleDelete(order['orderId']),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
