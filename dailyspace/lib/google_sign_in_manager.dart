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
    ],
  );
}
