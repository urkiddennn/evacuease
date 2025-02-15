import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../../../Models/message_model.dart';

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

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    _fetchMessagesFromAPI();
    _startAutoRefresh();
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
          setState(() {
            _apiMessages = newMessages;
            _isLoading = false;
          });

          if (newMessages.isNotEmpty) {
            Messages latestMessage = newMessages.first;
            showNotification(
              'New Message: ${latestMessage.subject}',
              latestMessage.message,
            );
          }
        }
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      setState(() => _isLoading = false);
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
    Future.delayed(const Duration(seconds: 10), () async {
      await _fetchMessagesFromAPI();
      _startAutoRefresh();
    });
  }

  String formatTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal();
    return DateFormat('MMM d, h:mm a').format(dateTime);
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
                            )),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.red[600],
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "${message.subject}",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      formatTime(message.createdAt),
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  message.message,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ));
                    },
                  ),
      ),
    );
  }
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
            //deletebutton
          ],
        ),
      ),
    );
  }
}
