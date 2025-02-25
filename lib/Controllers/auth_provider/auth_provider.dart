import 'package:evacuease/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProviders with ChangeNotifier {
  bool _isLoggedIn = false;
  User? _user;

  bool get isLoggedIn => _isLoggedIn;
  User? get user => _user;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthProviders() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _isLoggedIn = true;
      _user = currentUser;
    } else {
      _isLoggedIn = false;
      _user = null;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', _isLoggedIn);

    notifyListeners();
  }

  Future<void> login() async {
    _isLoggedIn = true;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      print("Starting Google sign-in process...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google sign-in canceled by user.");
        return;
      }

      print("Google user signed in: ${googleUser.email}");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      if (_user != null) {
        print("Prompting for additional data...");
        final userData = await _promptForUserData(context, _user!);

        if (userData == null || userData.isEmpty) {
          print("User data not provided (dialog canceled or empty).");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User profile completion was canceled.')),
          );
          return; // Stop the sign-in process
        }

        try {
          print("Creating new user in API...");
          await _createNewUserInAPI(_user!, userData);
        } catch (apiError) {
          print("Error creating user in API: $apiError");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create user: $apiError')),
          );
          return; // Stop the sign-in process
        }

        print("Updating login state...");
        await login();

        print("Navigating to MainScreen...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(initialIndex: 3)),
        );
      }
    } catch (e) {
      print("Error signing in with Google: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google: $e')),
      );
    }
  }

  Future<bool> _checkUserExistsInAPI(String email) async {
    try {
      print("Checking user existence in API for email: $email");
      final response = await http.get(
        Uri.parse('https://admin-evacu-ease.vercel.app/api/users?email=$email'),
      );
      print(
          "API response for user existence check: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> users = responseData['data'] ?? [];
        return users
            .isNotEmpty; // Return true if any user with this email exists
      } else {
        print(
            "API error checking user existence: ${response.statusCode} - ${response.body}");
        return false; // Assume user doesn’t exist on API failure
      }
    } catch (e) {
      print("Error checking user existence in API: $e");
      return false; // Assume user doesn’t exist on error
    }
  }

  Future<void> _createNewUserInAPI(
      User firebaseUser, Map<String, String> userData) async {
    try {
      final requestBody = {
        'username': firebaseUser.displayName ??
            firebaseUser.email?.split('@')[0] ??
            'User',
        'email': firebaseUser.email,
        'password': '', // No password required
        'role': 'user',
        'status': 'active',
        'location': userData['location'] ?? '', // Ensure location is provided
        'number': userData['number'] ?? '', // Ensure number is provided
      };

      // Validate required fields
      if (requestBody['location'] == '' || requestBody['number'] == '') {
        throw Exception('Location and number are required.');
      }

      print("Sending data to API: ${json.encode(requestBody)}");

      final response = await http.post(
        Uri.parse('https://admin-evacu-ease.vercel.app/api/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print(
          "API response for new user creation: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("User created successfully.");
      } else if (response.statusCode == 500) {
        throw Exception('Server error: ${response.body}');
      } else {
        try {
          final errorData = json.decode(response.body);
          print("API error details: ${errorData['message']}");
          throw Exception(
              'Failed to create user in API: ${errorData['message'] ?? 'Unknown error'}');
        } catch (e) {
          print("Error decoding API response: $e");
          throw Exception(
              'Failed to create user in API. Invalid API response.');
        }
      }
    } catch (e) {
      print("Error creating new user in API: $e");
      throw Exception('Failed to create user in API: $e');
    }
  }

  Future<Map<String, String>?> _promptForUserData(
      BuildContext context, User firebaseUser) async {
    final TextEditingController numberController = TextEditingController();
    String? selectedLocation;

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Complete Your Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: const OutlineInputBorder(),
                    errorText: numberController.text.isEmpty
                        ? 'Phone Number is required'
                        : null,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedLocation,
                  hint: const Text('Select Barangay'),
                  items:
                      ['Telaje', 'Bagong Lungsod', 'Dagokdok'].map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedLocation = value;
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    errorText: selectedLocation == null
                        ? 'Barangay is required'
                        : null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (numberController.text.isEmpty || selectedLocation == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill in all required fields')),
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  {
                    'number': numberController.text,
                    'location': selectedLocation!,
                  },
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> fetchUserData(String? userId) async {
    if (userId == null) return null;
    try {
      final response = await http.get(
        Uri.parse('https://admin-evacu-ease.vercel.app/api/users/$userId'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);
        return userData;
      } else {
        throw Exception('Failed to fetch user data');
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  Future<bool> updateUserData(
      Map<String, dynamic> userData, String userId) async {
    try {
      final response = await http.put(
        Uri.parse('https://admin-evacu-ease.vercel.app/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update user data');
      }
    } catch (e) {
      print("Error updating user data: $e");
      return false;
    }
  }
}
