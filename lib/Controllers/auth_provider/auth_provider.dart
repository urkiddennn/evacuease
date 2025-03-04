import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:evacuease/routes/route_names.dart';
import '../../Views/Screens/authentication_screen/Signup_screen.dart';

class AuthProviders with ChangeNotifier {
  bool _isLoggedIn = false;
  User? _user;
  String? _apiUserId;
  String? _name; // New field to store the user's name

  bool get isLoggedIn => _isLoggedIn;
  User? get user => _user;
  String? get apiUserId => _apiUserId;
  String? get name => _name; // Getter for the name

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthProviders() {
    // No initial check; LoadingScreen handles it
  }

  Future<void> checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _apiUserId = prefs.getString('apiUserId');
    _name = prefs.getString('userName'); // Load name from SharedPreferences

    if (_isLoggedIn && _apiUserId != null) {
      final userData = await fetchUserData(_apiUserId!);
      if (userData == null || userData['success'] != true) {
        await logoutWithoutNavigation();
      } else {
        _name = userData['data']['username'] ??
            userData['data']['name'] ??
            'Anonymous'; // Update name if available
        await _saveLoginState(_apiUserId); // Ensure name is saved
      }
    } else {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        _isLoggedIn = true;
        _user = currentUser;
        _name = currentUser.displayName ??
            currentUser.email?.split('@')[0] ??
            'Anonymous';
        await _saveLoginState(currentUser.uid);
      } else {
        _isLoggedIn = false;
        _user = null;
        _name = null;
      }
    }

    notifyListeners();
  }

  Future<bool> login({String? apiUserId, BuildContext? context}) async {
    if (apiUserId != null) {
      _apiUserId = apiUserId;
      // Fetch user data to get the name
      final userData = await fetchUserData(apiUserId);
      print("Login - User data: $userData");
      if (userData != null && userData['success'] == true) {
        _name = userData['data']['username'] ??
            userData['data']['name'] ??
            'Anonymous';
      } else {
        _name = 'Anonymous'; // Fallback if fetch fails
        print("Failed to fetch user data during login");
      }
    }

    _isLoggedIn = true;
    notifyListeners();
    await _saveLoginState(apiUserId);
    return true; // Login successful for API accounts
  }

  Future<void> _saveLoginState(String? userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    if (userId != null) {
      await prefs.setString('apiUserId', userId);
    }
    if (_name != null) {
      await prefs.setString('userName', _name!); // Save the name
    }
  }

  Future<void> logout(BuildContext context) async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _isLoggedIn = false;
    _user = null;
    _apiUserId = null;
    _name = null; // Clear name on logout
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('apiUserId');
    await prefs.remove('userName'); // Clear stored name
    Navigator.pushReplacementNamed(context, RouteNames.signin);
  }

  Future<void> logoutWithoutNavigation() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _isLoggedIn = false;
    _user = null;
    _apiUserId = null;
    _name = null; // Clear name
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('apiUserId');
    await prefs.remove('userName');
  }

  Future<void> signInWithGoogle(BuildContext context,
      {bool fromSignup = false}) async {
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
        final exists = await _checkUserExistsInAPI(_user!.email!);
        if (!exists && !fromSignup) {
          print("Email not registered, redirecting to SignupScreen");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Email not registered. Please sign up.')),
          );
          await _googleSignIn.signOut();
          await _auth.signOut();
          _user = null;
          _name = null;
          Navigator.pushReplacementNamed(context, RouteNames.signup);
          return;
        }

        if (!exists && fromSignup) {
          print("Prompting for additional data...");
          final userData = await _promptForUserData(context, _user!);

          if (userData == null || userData.isEmpty) {
            print("User data not provided.");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('User profile completion was canceled.')),
            );
            await _googleSignIn.signOut();
            await _auth.signOut();
            _user = null;
            _name = null;
            return;
          }

          try {
            print("Creating new user in API...");
            await _createNewUserInAPI(_user!, userData);
          } catch (apiError) {
            print("Error creating user in API: $apiError");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create user: $apiError')),
            );
            await _googleSignIn.signOut();
            await _auth.signOut();
            _user = null;
            _name = null;
            return;
          }
        }

        // Set name for Google login
        _name =
            _user!.displayName ?? _user!.email?.split('@')[0] ?? 'Anonymous';
        print("Google login - Name set to: $_name");

        print("Updating login state...");
        await login(apiUserId: _user!.uid);

        print("Navigating to MainScreen...");
        Navigator.pushReplacementNamed(context, RouteNames.mainScreen);
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
        return users.isNotEmpty; // True if user exists
      } else {
        print(
            "API error checking user existence: ${response.statusCode} - ${response.body}");
        return false; // Assume doesn’t exist on API failure
      }
    } catch (e) {
      print("Error checking user existence in API: $e");
      return false; // Assume doesn’t exist on error
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
        'password': '',
        'role': 'user',
        'status': 'active',
        'location': userData['location'] ?? '',
        'number': userData['number'] ?? '',
      };

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
      } else {
        throw Exception('Failed to create user in API: ${response.body}');
      }
    } catch (e) {
      print("Error creating new user in API: $e");
      throw e;
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
        print("fetchUserData response: $userData");
        return userData;
      } else {
        print(
            "Failed to fetch user data: ${response.statusCode} - ${response.body}");
        return null;
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
