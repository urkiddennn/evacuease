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
    bool isSubmitting = false;

    String name = authProvider.name ?? 'Anonymous';
    String? userId = authProvider.apiUserId ?? authProvider.user?.uid;

    print(
        "API User ID: ${authProvider.apiUserId}, Firebase User: ${authProvider.user?.uid}, Name: $name");

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    type == 'bug' ? Icons.bug_report : Icons.feedback,
                    color: Colors.red[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type == 'bug' ? language.reportBug : language.sendFeedback,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your input helps us improve EvacuEase!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: type == 'bug'
                            ? language.reportBug
                            : language.feedback,
                        hintText: type == 'bug'
                            ? 'Describe the bug you encountered...'
                            : 'Share your thoughts or suggestions...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (messageController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter some text')),
                            );
                            return;
                          }

                          setState(() {
                            isSubmitting = true;
                          });

                          final feedback = Feedback.Feedback(
                            name: name,
                            date: DateTime.now()
                                .toString()
                                .split(' ')[0], // "YYYY-MM-DD"
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
                                const SnackBar(
                                    content: Text('Submission successful!')),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Failed to submit: ${response.statusCode}')),
                              );
                            }
                          } catch (e) {
                            print("Error submitting feedback: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error submitting: $e')),
                            );
                          } finally {
                            setState(() {
                              isSubmitting = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchAboutData() async {
    try {
      final response = await http.get(
        Uri.parse('https://admin-evacu-ease.vercel.app/api/about'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'].isNotEmpty) {
          return jsonData['data'][0]; // Return the first item in the data array
        }
      }
      return null; // Return null if fetch fails or no data
    } catch (e) {
      print("Error fetching about data: $e");
      return null;
    }
  }

  void _showAboutDialog(BuildContext context) {
    final language = Provider.of<Language>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _fetchAboutData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return AlertDialog(
                title: Text(language.about),
                content: const Text(
                  'Failed to load about information. Please try again later.',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            }

            final aboutData = snapshot.data!;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    language.about,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aboutData['details'] ?? 'No details available',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mission',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      aboutData['mission'] ?? 'No mission statement available',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vision',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      aboutData['vision'] ?? 'No vision statement available',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phone: ${aboutData['phoneNumber'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Email: ${aboutData['email'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
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
