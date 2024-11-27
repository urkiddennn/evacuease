import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:readsms/readsms.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _plugin = Readsms();
  List<Map<String, String>> _notifications = [];
  String _targetSender =
      "+639708843944"; // Replace this with the desired sender (e.g., "+1234567890").
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndListen();
  }

  Future<void> _checkPermissionAndListen() async {
    bool hasPermission = await _getPermission();
    if (hasPermission) {
      setState(() {
        _isPermissionGranted = true;
      });

      _plugin.read();
      _plugin.smsStream.listen((event) {
        if (event.sender == _targetSender) {
          setState(() {
            _notifications.add({
              "body": event.body ?? "No content",
              "sender": event.sender ?? "Unknown sender",
              "time": event.timeReceived.toString(),
            });
          });
        }
      });
    } else {
      setState(() {
        _isPermissionGranted = false;
      });
    }
  }

  Future<bool> _getPermission() async {
    if (await Permission.sms.status == PermissionStatus.granted) {
      return true;
    } else {
      if (await Permission.sms.request() == PermissionStatus.granted) {
        return true;
      }
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _plugin.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification"),
      ),
      body: _isPermissionGranted
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: _notifications.isEmpty
                      ? [
                          Center(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/icons/remove.png",
                                width: 100,
                              ),
                              Text("No messages available!",
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 20))
                            ],
                          ))
                        ]
                      : _notifications.map((notification) {
                          final body = notification["body"] ?? "No content";
                          final sender =
                              notification["sender"] ?? "Unknown sender";
                          final time = notification["time"] ?? "Unknown time";

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.notifications_active,
                                      color: Colors.red,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sender,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            body,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            time,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                ),
              ),
            )
          : const Center(
              child: Text(
                  "SMS permissions are required to display notifications."),
            ),
    );
  }
}
