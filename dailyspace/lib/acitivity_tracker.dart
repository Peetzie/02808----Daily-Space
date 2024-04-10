import 'dart:convert';
import 'dart:developer';

import 'package:dailyspace/google_http_client.dart';
import 'package:dailyspace/login_screen.dart';
import 'package:dailyspace/tasks_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/src/response.dart';
import 'vis.dart';
import 'google_sign_in_manager.dart';

class TaskInfo {
  final String taskId;
  final String title;

  TaskInfo(this.taskId, this.title);
}

class ActivityTracker extends StatefulWidget {
  const ActivityTracker({Key? key}) : super(key: key);

  @override
  _ActivityTrackerState createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends State<ActivityTracker> {
  Map<String, Map<String, dynamic>> availableActivities = {};
  Set<TaskInfo> activeActivities = {};

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    final tasks = await TaskService.fetchTasksForList(account);
    tasks.values.forEach((task) {
      setState(() {
        availableActivities[task['taskId']] = {
          'title': task['title'],
          'due': task['due'],
        };
      });
    });
    log(" List of available activities fetched on reload: $availableActivities");
  }

  final GoogleSignInAccount? account =
      GoogleSignInManager.instance.googleSignIn.currentUser;

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
                  onPressed: () async {
                    log("Resyncing");
                    await _fetchActivities();
                  },
                  tooltip: "Sync with Google",
                  icon: const Icon(Icons.sync),
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
                      data: activeActivities.elementAt(index).taskId,
                      feedback: Container(
                        height: 100,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            activeActivities.elementAt(index).title,
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
                            activeActivities.elementAt(index).title,
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
                              String taskId = data.data;
                              log(taskId);
                              activeActivities.add(TaskInfo(taskId,
                                  availableActivities[taskId]?['title'] ?? ''));
                              availableActivities.remove(
                                  taskId); // Remove the taskId from availableActivities
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
                              log(data.data);
                              // activeActivities.remove(data);
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
                  final taskId = availableActivities.keys.elementAt(index);
                  final taskInfo = availableActivities[taskId];
                  return LongPressDraggable<String>(
                    data: taskId,
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
                          taskInfo?['title'] ?? '',
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
                          taskInfo?['title'] ?? '',
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
              title: const Text('Visualization'),
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
}
