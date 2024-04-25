import 'dart:developer';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:dailyspace/screens/acitivity_tracker.dart';
import 'package:dailyspace/services/firebase_handler.dart';
import 'package:dailyspace/services/google_sign_in_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                _signInWithGoogle(context);
                // _testCase(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    log('Attempting Google Sign-In');
    try {
      final GoogleSignIn googleSignIn =
          GoogleSignInManager.instance.googleSignIn;
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        // Use the credentials to sign in with Firebase
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          log('Signed in with Google: ${user.uid}');
          FirebaseManager firebaseManager = FirebaseManager();
          await firebaseManager.addUser().catchError((error) {
            log("Failed to add user to Firestore: $error");
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ActivityTracker()),
          );
        } else {
          log('Failed to sign in with Google: No user in Firebase');
        }
      } else {
        log('Google sign-in aborted by user');
      }
    } catch (error) {
      log('Error signing in with Google: $error');
    }
  }
}
