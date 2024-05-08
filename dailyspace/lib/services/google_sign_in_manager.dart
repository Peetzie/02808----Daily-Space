/*
  Created by: 
  - Frederik Peetz-Schou Larsen
  As part of course 02808 at DTU 2024. 
*/
import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInManager {
  GoogleSignInManager._privateConstructor();

  static final GoogleSignInManager _instance =
      GoogleSignInManager._privateConstructor();

  static GoogleSignInManager get instance => _instance;

  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/tasks'
    ],
  );

  Future<void> signOut() async {
    await googleSignIn.signOut();
    googleSignIn.disconnect(); // Ensures the user session is fully cleared.
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await googleSignIn.signIn();
    } catch (e) {
      // Handle errors here if needed
      log(e.toString());
      return null;
    }
  }

  GoogleSignInAccount? get currentUser => googleSignIn.currentUser;
}
