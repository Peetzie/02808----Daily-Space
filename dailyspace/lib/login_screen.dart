import 'dart:developer';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:dailyspace/acitivity_tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_sign_in_manager.dart';

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
      // Use the shared instance of GoogleSignIn
      final GoogleSignIn googleSignIn =
          GoogleSignInManager.instance.googleSignIn;
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        bool isAuthorized =
            true; // Simplification, as we know the account is not null

        // If user is authorized, navigate to activity tracker
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ActivityTracker()),
        );
      } else {
        print('User did not grant all required permissions');
      }
    } catch (error) {
      print('Error signing in with Google: $error');
    }
  }
}
