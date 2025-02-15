import 'package:flutter/material.dart';
import 'package:evacuease/Views/Screens/authentication_screen/Signin_screen.dart';
import 'package:evacuease/Views/Screens/authentication_screen/Signup_screen.dart';
import 'package:evacuease/Views/Screens/loading_screen.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  int currentStep = 0;

  // Define onboarding data
  final List<Map<String, String>> onboardingData = [
    {
      'imagePath': 'assets/images/bg-1.jpg',
      'title': 'Discover an easier route in Tandag City during disaster',
      'description':
          'Lorem epso, hello my beautiful wifey. This is a sample text for the app.',
    },
    {
      'imagePath': 'assets/images/bg-2.jpg',
      'title': 'Real-time Alerts for Safe Evacuation',
      'description':
          'Stay updated with real-time alerts and evacuation guides to stay safe.',
    },
    {
      'imagePath': 'assets/images/bg-2.jpg',
      'title': 'Discover an easier route in Tandag City during disaster',
      'description':
          'Stay updated with real-time alerts and evacuation guides to stay safe.',
    }
  ];

  void nextStep() {
    setState(() {
      if (currentStep < onboardingData.length) {
        currentStep++;
      } else {
        // Implement navigation to Sign Up / Sign In screen or display options
      }
    });
  }

  void skipOnboarding() {
    // Implement skip functionality (e.g., go directly to Sign Up / Sign In)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            // Illustration (replace with an asset or network image)
            Container(
              height: 250,
              child: Image.asset(
                onboardingData[currentStep]['imagePath']!,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 24),
            // Title
            Text(
              onboardingData[currentStep]['title']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            // Description
            Text(
              onboardingData[currentStep]['description']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            // Step Indicator

            SizedBox(
              height: 20,
            ),
            // Conditional display for last screen
            currentStep == onboardingData.length - 1
                ? Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignupScreen()));

                            // Navigate to Sign Up screen
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SigninScreen()));
                            // Navigate to Sign Up screen
                          },
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoadingScreen()));
                        },
                        child: Text(
                          'Skip',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          onboardingData.length,
                          (index) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: CircleAvatar(
                              radius: 6,
                              backgroundColor: index == currentStep
                                  ? Colors.red
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: nextStep,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                    ],
                  ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
