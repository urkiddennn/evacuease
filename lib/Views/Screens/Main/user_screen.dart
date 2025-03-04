import 'package:evacuease/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evacuease/Controllers/auth_provider/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../Models/feedback_model.dart' as Feedback;
import '../../../Controllers/language.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  Future<void> _submitFeedback(BuildContext context, String type) async {
    final authProvider = Provider.of<AuthProviders>(context, listen: false);
    final language = Provider.of<Language>(context, listen: false);
    final TextEditingController messageController = TextEditingController();

    // Use stored name and ID from AuthProviders
    String name = authProvider.name ?? 'Anonymous';
    String? userId = authProvider.apiUserId ?? authProvider.user?.uid;

    print(
        "API User ID: ${authProvider.apiUserId}, Firebase User: ${authProvider.user?.uid}, Name: $name");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(type == 'bug' ? language.reportBug : language.sendFeedback),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: type == 'bug'
                        ? 'Describe the bug you encountered...'
                        : 'Share your feedback...',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter some text')),
                  );
                  return;
                }

                final feedback = Feedback.Feedback(
                  name: name,
                  date: DateTime.now().toString().split(' ')[0], // "YYYY-MM-DD"
                  userId: userId,
                  message: messageController.text.trim(),
                );

                try {
                  final payload = feedback.toJson();
                  print(
                      "Submitting feedback with payload: ${json.encode(payload)}");

                  final response = await http.post(
                    Uri.parse(
                        'https://admin-evacu-ease.vercel.app/api/feedbacks'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode(payload),
                  );

                  print(
                      "Feedback submission response: ${response.statusCode} - ${response.body}");

                  if (response.statusCode == 200 ||
                      response.statusCode == 201) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Submission successful!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Failed to submit: ${response.statusCode} - ${response.body}')),
                    );
                  }
                } catch (e) {
                  print("Error submitting feedback: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error submitting: $e')),
                  );
                }

                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    final language = Provider.of<Language>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(language.about),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EvacuEase is a disaster preparedness and evacuation assistance app designed to help users stay safe during emergencies.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'Version: 1.0.0',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  'Developed by: Your Name/Team',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  '© 2025 EvacuEase. All rights reserved.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languageProvider = Provider.of<Language>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(languageProvider.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                onTap: () {
                  languageProvider.setLanguage('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Tagalog'),
                onTap: () {
                  languageProvider.setLanguage('tl');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Bisaya'),
                onTap: () {
                  languageProvider.setLanguage('ceb');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviders>(context);
    final language = Provider.of<Language>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(language.settings),
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {},
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "General",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildListTile(
                icon: Icons.info_outline,
                title: language.about,
                onTap: () => _showAboutDialog(context),
              ),
              _buildListTile(
                icon: Icons.language_outlined,
                title: language.language,
                onTap: () => _showLanguageDialog(context),
              ),
              _buildListTile(
                icon: Icons.logout,
                title: language.logout,
                titleColor: Colors.red,
                onTap: () async {
                  await authProvider.logout(context);
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "Feedback",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildListTile(
                icon: Icons.bug_report_outlined,
                title: language.reportBug,
                onTap: () => _submitFeedback(context, 'bug'),
              ),
              _buildListTile(
                icon: Icons.feedback_outlined,
                title: language.sendFeedback,
                onTap: () => _submitFeedback(context, 'feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black87),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: titleColor ?? Colors.black87,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        const Divider(),
      ],
    );
  }
}
