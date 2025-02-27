import 'package:flutter/material.dart';
import 'dart:ui';

class Feedback {
  final String name;
  final String date;
  final String? userId; // Nullable since it might not always be present
  final String message;
  final bool read;

  Feedback({
    required this.name,
    required this.date,
    this.userId,
    required this.message,
    this.read = false, // Default value as per schema
  });

  // Convert Feedback object to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'userID': userId,
      'message': message,
      'read': read,
    };
  }

  // Create Feedback object from JSON (for potential API response)
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
