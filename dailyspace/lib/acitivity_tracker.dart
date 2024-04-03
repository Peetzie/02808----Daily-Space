import 'dart:convert';
import 'dart:developer';

import 'package:dailyspace/google_http_client.dart';
import 'package:dailyspace/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'vis.dart';
import 'google_sign_in_manager.dart';

class ActivityTracker extends StatefulWidget {
  const ActivityTracker({super.key});

  @override
  _ActivityTrackerState createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends State<ActivityTracker> {
  List<String> availableActivities =
      List.generate(4000000, (index) => 'Activity ${index + 1}');
  List<String> activeActivities = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightBlueAccent, Colors.lightGreenAccent],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: const Text(
                "Main Activity window",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    fetchTasks(); // Call fetchTasks when the button is pressed
                  },
                  icon: const Icon(Icons.download),
                  tooltip: 'Fetch Tasks',
                  color: Colors.white,
                ),
                IconButton(
                  onPressed: () async {
                    await GoogleSignInManager.instance.googleSignIn.signOut();
                    // Navigate back to login screen
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const LoginScreen()));
                  },
                  icon: const Icon(Icons.logout),
                  color: Colors.white,
                )
              ],
            ),
            Container(
              height: 150,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white, width: 1.0),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: activeActivities.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: LongPressDraggable<String>(
                      data: activeActivities[index],
                      feedback: Container(
                        height: 100,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            activeActivities[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Container(),
                      child: Container(
                        height: 100,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            activeActivities[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue
                              .withOpacity(0.8), // Transparent blue color
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DragTarget<String>(
                          builder: (context, candidateData, rejectedData) {
                            return const Center(
                              child: Text(
                                "Begin Activity",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                            );
                          },
                          onAcceptWithDetails: (data) {
                            setState(() {
                              activeActivities.add(data as String);
                              availableActivities.remove(data);
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green
                              .withOpacity(0.8), // Transparent blue color
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DragTarget<String>(
                          builder: (context, candidateData, rejectedData) {
                            return const Center(
                              child: Text(
                                "End Activity",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                            );
                          },
                          onAcceptWithDetails: (data) {
                            setState(() {
                              activeActivities.remove(data);
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 150,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white, width: 1.0),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: availableActivities.length,
                itemBuilder: (context, index) {
                  return LongPressDraggable<String>(
                    data: availableActivities[index],
                    feedback: Container(
                      height: 100,
                      width: 150,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          availableActivities[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Container(),
                    child: Container(
                      height: 100,
                      width: 150,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          availableActivities[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.lightBlueAccent, Colors.lightGreenAccent],
                ),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Main Menu'),
              onTap: () {
                // Add functionality for Option 1
              },
            ),
            ListTile(
              title: const Text('Visualisation'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OptionTwoPage()),
                );
              },
            ),
            // Add more ListTile widgets for additional menu options
          ],
        ),
      ),
    );
  }

  void fetchTasks() async {
    final GoogleSignInAccount? account =
        GoogleSignInManager.instance.googleSignIn.currentUser;

    if (account != null) {
      final authHeaders = await account.authHeaders;
      final googleHttpClient = GoogleHttpClient(authHeaders);
      final url =
          Uri.parse('https://www.googleapis.com/tasks/v1/users/@me/lists');

      final response = await googleHttpClient.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print(data);
      } else {
        print('Failed to fetch tasks -- Status code: ${response.statusCode}');
      }
    }
  }
}
