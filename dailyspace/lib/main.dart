import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Import your login screen widget
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/acitivity_tracker.dart';
import 'screens/vis.dart';
import 'screens/setting.dart';
import 'screens/calendar.dart';
import 'dart:developer';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:dailyspace/screens/acitivity_tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../google/google_sign_in_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:dailyspace/activity_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

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
            MaterialPageRoute(builder: (context) => const MainScreen()),
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActivityManager>(
      create: (_) => ActivityManager(),
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            ActivityTracker(),
            Consumer<ActivityManager>(
              builder: (context, manager, child) =>
                  Calendar(availableActivities: manager.availableActivities),
            ),
            OptionTwoPage(),
            SettingsPage2(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Tracker',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'Visualize',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }
}
