import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:laza/order_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onNotificationUpdated;

  const NotificationsScreen({super.key, required this.onNotificationUpdated});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final String? userId = prefs.getString('userId');

    if (token == null || userId == null) {
      print("No token or userId found, user might not be authenticated.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://pa-gebeya-backend.onrender.com/api/users/notifications/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final validNotifications = (data['notifications'] as List)
            .where((notification) => notification['orderId'] != null)
            .toList();

        for (var notification in validNotifications) {
          notification['message'] =
              _convertHtmlToPlainText(notification['message']);
        }

        setState(() {
          notifications = validNotifications;
          isLoading = false;
        });
      } else {
        print("Failed to fetch notifications: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching notifications: $error");
    }
  }

  String _convertHtmlToPlainText(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  Future<void> removeNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      print("No token found, user might not be authenticated.");
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse(
            'https://pa-gebeya-backend.onrender.com/api/users/notifications/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications
              .removeWhere((notification) => notification['_id'] == id);
        });
        widget.onNotificationUpdated();
      } else {
        print("Failed to remove notification: ${response.statusCode}");
      }
    } catch (error) {
      print("Error removing notification: $error");
    }
  }

  Future<void> handleNotificationClick(dynamic notification) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      print("No token found, user might not be authenticated.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://pa-gebeya-backend.onrender.com/api/orders/${notification['orderId']}/${notification['userId']}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final orderData = jsonDecode(response.body);
        print("Order details retrieved successfully: $orderData");

        // Get the order creation time from the order data
        final createdAt = orderData['createdAt'] != null
            ? DateTime.parse(orderData['createdAt'])
            : DateTime.now();

        // Navigate to the order detail screen with both orderId and creation time
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(
              orderId: notification['orderId'],
              orderCreationTime: createdAt,
            ),
          ),
        );
      } else {
        print("Failed to fetch order details: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching order details: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Theme.of(context).textTheme.headlineSmall?.color,
          ),
        ),
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
          : notifications.isEmpty
              ? Center(
                  child: Text(
                    'No notifications found.',
                    style: TextStyle(
                        fontSize: 16, color: Theme.of(context).hintColor),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 16),
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          'Order #${notification['orderId']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        subtitle: Text(
                          notification['message'],
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close,
                              color: Theme.of(context).colorScheme.error),
                          onPressed: () =>
                              removeNotification(notification['_id']),
                        ),
                        onTap: () => handleNotificationClick(notification),
                      ),
                    );
                  },
                ),
    );
  }
}
