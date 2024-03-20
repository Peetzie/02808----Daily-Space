import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ActivityTracker(),
    );
  }
}

class ActivityTracker extends StatefulWidget {
  const ActivityTracker({Key? key}) : super(key: key);

  @override
  _ActivityTrackerState createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends State<ActivityTracker> {
  List<String> availableActivities =
      List.generate(40, (index) => 'Activity ${index + 1}');
  List<String> activeActivities = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
              leading: const Icon(
                Icons.menu,
                color: Colors.white,
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.logout),
                  color: Colors.white,
                )
              ],
            ),
            Container(
              height: 150,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
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
                          onAccept: (data) {
                            setState(() {
                              activeActivities.add(data);
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
                          onAccept: (data) {
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
              decoration: BoxDecoration(
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
    );
  }
}
