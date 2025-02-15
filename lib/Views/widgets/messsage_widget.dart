import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:evacuease/Models/message_model.dart';
import '../Screens/main/notification_screen.dart';

class MessageDetailScreen extends StatelessWidget {
  final Messages message;
  const MessageDetailScreen({super.key, required this.message});

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
