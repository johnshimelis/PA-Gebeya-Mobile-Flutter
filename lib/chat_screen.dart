import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5, // Replace with actual chat count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundImage: AssetImage(
                    'assets/images/user.png'), // Replace with actual user image
              ),
              title: Text('User ${index + 1}'),
              subtitle: const Text('Last message: Hello!'),
              trailing: const Icon(Icons.chat, color: Colors.green),
              onTap: () {
                // Navigate to chat conversation screen
                debugPrint('Chat with User ${index + 1} tapped');
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Start a new chat
          debugPrint('Start a new chat');
        },
        child: const Icon(Icons.message),
      ),
    );
  }
}
