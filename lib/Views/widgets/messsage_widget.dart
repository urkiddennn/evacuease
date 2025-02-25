import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:evacuease/Models/message_model.dart';
import '../Screens/main/notification_screen.dart';

class MessageDetailScreen extends StatelessWidget {
  final Messages message;
  const MessageDetailScreen({super.key, required this.message});
  String formatTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hrs ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(message.subject)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${message.type}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              formatTime(message.createdAt),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Text(
              message.message,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
