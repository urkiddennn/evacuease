import 'package:flutter/material.dart';
import 'dart:ui';

class Feedback {
  final String name;
  final String date;
  final String? userId;
  final String message;
  final bool read;

  Feedback({
    required this.name,
    required this.date,
    this.userId,
    required this.message,
    this.read = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date, // Keep ISO format for now, adjust if needed
      'userID': userId, // Matches server response
      'message': message,
      'read': read,
    };
  }

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      name: json['name'] as String,
      date: json['date'] as String,
      userId: json['userID'] as String?,
      message: json['message'] as String,
      read: json['read'] as bool? ?? false,
    );
  }
}
