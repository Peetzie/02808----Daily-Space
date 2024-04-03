import 'dart:developer';

import 'package:auth_buttons/auth_buttons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'acitivity_tracker.dart';

// Scopes required by this application
const List<String> scopes = <String>[
  'email',
  'https://www.googleapis.com/auth/contacts.readonly',
];

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GoogleAuthButton(
              onPressed: () {
                _testCase(context);
                _signInWithGoogle(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testCase(BuildContext context) async {
    log("testing");
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    print('Attempting Google Sign-In');
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: scopes);
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        bool isAuthorized = googleSignInAccount != null;

        // Check for web platform and authorization
        if (kIsWeb) {
          isAuthorized = await googleSignInAccount.authHeaders != null;
        }

        // If user is authorized, navigate to activity tracker
        if (isAuthorized) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ActivityTracker()),
          );
        } else {
          // Request additional permissions if needed
          final bool authorizedScopes =
              await googleSignIn.requestScopes(scopes);
          if (authorizedScopes) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ActivityTracker()),
            );
          } else {
            // Handle the scenario where the user didn't grant all required permissions
            // You can show a dialog or a message here
            print('User did not grant all required permissions');
          }
        }
      }
    } catch (error) {
      print('Error signing in with Google: $error');
      // Handle error as needed
    }
  }
}
