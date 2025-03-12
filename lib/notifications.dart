import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:laza/order_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
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

        // Convert HTML messages to plain text
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

  // Convert HTML to plain text
  String _convertHtmlToPlainText(String html) {
    // Remove HTML tags using regex
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

        // Navigate to the order detail screen with orderId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderDetailScreen(orderId: notification['orderId']),
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
        title: Text('Notifications'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Text(
                    'No notifications found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          'Order #${notification['orderId']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          notification['message'],
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
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
