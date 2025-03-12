import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_detail_screen.dart'; // Import the OrderDetailScreen

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

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
      }
    } catch (error) {
      print('Error deleting order: $error');
    }
  }

  void handleViewDetails(dynamic order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: order['orderId']),
      ),
    );
  }

  TextStyle getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const TextStyle(
            color: Colors.orange, fontWeight: FontWeight.bold);
      case 'cancelled':
      case 'un-paid':
        return const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
      case 'approved':
      case 'delivered':
      case 'paid':
        return const TextStyle(
            color: Colors.green, fontWeight: FontWeight.bold);
      case 'processing':
        return const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold);
      default:
        return const TextStyle(color: Colors.black);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No orders found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        leading:
                            const Icon(Icons.shopping_bag, color: Colors.blue),
                        title: Text('Order #${order['orderId']}'),
                        subtitle: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: <TextSpan>[
                              const TextSpan(text: 'Status: '),
                              TextSpan(
                                text: order['status'],
                                style: getStatusStyle(order['status']),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => handleViewDetails(order),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => handleDelete(order['orderId']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
