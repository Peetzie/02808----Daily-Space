
/*
  Created by: 
  - Zheng Dong
  - Frederik Peetz-Schou Larsen
  As part of course 02808 at DTU 2024. 
*/
import 'package:dailyspace/datastructures/calendar_manager.dart';
import 'package:dailyspace/datastructures/data_manager.dart';
import 'package:dailyspace/screens/acitivity_tracker.dart';
import 'package:dailyspace/screens/calendar.dart';
import 'package:dailyspace/screens/setting.dart';
import 'package:dailyspace/screens/vis.dart';
import 'package:dailyspace/services/google_sign_in_manager.dart';
import 'package:dailyspace/widgets/activity_tracker/activity_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart'; // Importing the LoginScreen file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  GoogleSignInAccount? account = GoogleSignInManager.instance.currentUser;

  Widget initialScreen;
  if (account != null) {
    CalendarManager calendarManager = CalendarManager();
    DataManager dataManager = DataManager(calendarManager: calendarManager);
    await calendarManager.fetchCalendars(account);
    initialScreen =
        MainScreen(calendarManager: calendarManager, dataManager: dataManager);
  } else {
    initialScreen = const LoginScreen();
  }
  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}

class MainScreen extends StatefulWidget {
  final CalendarManager calendarManager;
  final DataManager dataManager;
  const MainScreen(
      {Key? key, required this.calendarManager, required this.dataManager})
      : super(key: key);
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late CalendarManager calendarManager;
  late DataManager dataManager;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    calendarManager = widget.calendarManager;
    dataManager = widget.dataManager;
  }

  @override
  Widget build(BuildContext context) {
    log("initial mainscreen calendars " +
        calendarManager.availableCalendars.toString());
    return ChangeNotifierProvider<ActivityManager>(
      create: (_) => ActivityManager(),
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            ActivityTracker(
              calendarManager: widget.calendarManager,
              dataManager: widget.dataManager,
            ),
            Consumer<ActivityManager>(
              builder: (context, manager, child) =>
                  Calendar(availableActivities: manager.availableActivities),
            ),
            const OptionTwoPage(),
            SettingsPage2(
              calendarManager: widget.calendarManager,
              dataManager: widget.dataManager,
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                Icons.dashboard,
                color: Colors.black,
              ),
              label: 'Tracker',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.calendar_today,
                color: Colors.black,
              ),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.show_chart,
                color: Colors.black,
              ),
              label: 'Visualize',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.settings,
                color: Colors.black,
              ),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor:
              Colors.purple, // Change the selected item color to purple
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }
}

// Add the SettingsPage2 widget definition here

