import 'package:auth_buttons/auth_buttons.dart';
import 'package:dailyspace/datastructures/calendar_manager.dart';
import 'package:dailyspace/datastructures/data_manager.dart';
import 'package:dailyspace/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    CalendarManager calendarManager = CalendarManager();

    DataManager dataManager = DataManager(calendarManager: calendarManager);
    log('Attempting Google Sign-In');
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
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
          await calendarManager.fetchCalendars(googleSignInAccount);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MainScreen(
                      calendarManager: calendarManager,
                      dataManager: dataManager,
                    )),
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
