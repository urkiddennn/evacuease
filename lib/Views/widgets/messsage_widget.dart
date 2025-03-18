import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:evacuease/Models/message_model.dart';

import '../Screens/main/location_screen.dart';

class MessageDetailScreen extends StatelessWidget {
  final Messages message;
  const MessageDetailScreen({super.key, required this.message});

  String formatDetailedTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal();
    return DateFormat('MMMM d, yyyy, h:mm a').format(dateTime);
  }

  IconData getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return Icons.warning;
      case 'alert':
        return Icons.error;
      case 'emergency':
        return Icons.priority_high;
      default:
        return Icons.notification_important;
    }
  }

  Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return Colors.orange[800]!;
      case 'alert':
        return Colors.red[800]!;
      case 'emergency':
        return Colors.red[900]!;
      default:
        return Colors.blueGrey[700]!;
    }
  }

  void _navigateToLocation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationScreen(
          triggerEmergencyRoute: true,
          emergencyType: message.emergencyType, // Pass emergencyType
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          message.subject,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    getIconForType(message.type),
                    color: getTypeColor(message.type),
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: getTypeColor(message.type),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                formatDetailedTime(message.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message.message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
              if (message.type.toLowerCase() == 'emergency') ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _navigateToLocation(context),
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text(
                    "Navigate to Evacuation",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
