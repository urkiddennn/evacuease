import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../../../Models/message_model.dart';
import 'location_screen.dart'; // Adjust path if necessary

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id',
    'Your Channel Name',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: DarwinNotificationDetails(),
  );
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
  );
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Messages> _apiMessages = [];
  bool _isLoading = true;
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    _fetchMessagesFromAPI();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _fetchMessagesFromAPI() async {
    final uri = Uri.parse('https://admin-evacu-ease.vercel.app/api/messages');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        List<dynamic> jsonData = responseData['data'];
        List<Messages> newMessages =
            jsonData.map((msg) => Messages.fromJson(msg)).toList();
        newMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (!_areListsEqual(_apiMessages, newMessages)) {
          if (mounted) {
            setState(() {
              _apiMessages = newMessages;
              _isLoading = false;
            });

            if (newMessages.isNotEmpty) {
              Messages latestMessage = newMessages.first;
              showNotification(
                'New Message: ${latestMessage.name}',
                latestMessage.message,
              );
            }
          }
        }
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _areListsEqual(List<Messages> list1, List<Messages> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _fetchMessagesFromAPI();
    });
  }

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

  String truncateText(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  IconData getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return Icons.warning;
      case 'alert':
        return Icons.error;
      case 'immediately':
        return Icons.priority_high;
      default:
        return Icons.notification_important;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _apiMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/icons/remove.png",
                          width: 100,
                        ),
                        Text(
                          "No messages available!",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _apiMessages.length,
                    itemBuilder: (context, index) {
                      Messages message = _apiMessages[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MessageDetailScreen(message: message),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1.0,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 90,
                              maxHeight: 110,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  getIconForType(message.type),
                                  color: Colors.red[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        truncateText(message.name,
                                            maxLength: 30),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        truncateText(message.message,
                                            maxLength: 50),
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[500]),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  formatTime(message.createdAt),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

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
      case 'immediately':
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
      case 'immediately':
        return Colors.red[900]!;
      default:
        return Colors.blueGrey[700]!;
    }
  }

  void _navigateToLocation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationScreen(triggerEmergencyRoute: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          message.name,
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
              if (message.type.toLowerCase() == 'immediately') ...[
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
