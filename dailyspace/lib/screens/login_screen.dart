import 'dart:developer';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:dailyspace/screens/acitivity_tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../google/google_sign_in_manager.dart';
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
          addUser("test", "test@gmail.com", 21); // Example call
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

  Future<void> addUser(String name, String email, int age) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentReference userDoc = firestore.collection('users').doc(user.uid);

      return userDoc
          .set({
            'name': name,
            'email': email,
            'age': age,
          })
          .then((value) => log("User added successfully!"))
          .catchError((error) => log("Failed to add user: $error"));
    } else {
      log("User is not authenticated");
      throw Exception('User is not authenticated');
    }
  }
}
