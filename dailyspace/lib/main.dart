import 'dart:async';
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

String _formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitHours = twoDigits(d.inHours);
  String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
  return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
}

class Activity {
  String name;
  DateTime startTime;
  Timer? countdownTimer;
  Duration remainingTime = Duration(minutes: 1);

  Activity({required this.name, required this.startTime});

  void startCountdown(
      void Function() onFinish, void Function(Duration) onTick) {
    final oneSec = Duration(seconds: 1);
    remainingTime = Duration(minutes: 1);
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(oneSec, (Timer timer) {
      if (remainingTime == Duration(seconds: 0)) {
        timer.cancel();
        onFinish();
      } else {
        remainingTime = remainingTime - oneSec;
        onTick(remainingTime);
      }
    });
  }
}

class ActivityTracker extends StatefulWidget {
  const ActivityTracker({Key? key}) : super(key: key);

  @override
  _ActivityTrackerState createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends State<ActivityTracker> {
  List<Activity> availableActivities = [];
  List<Activity> activeActivities = [];
  List<Activity> beginActivities = [];
  List<Activity> endActivities = [];

  @override
  void initState() {
    super.initState();
    DateTime currentTime = DateTime.now();
    availableActivities = List.generate(10, (index) {
      return Activity(
          name: 'Activity ${index + 1}',
          startTime: currentTime.add(Duration(hours: index)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Tracker'),
      ),
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
                "My App Bar",
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
                  return LongPressDraggable<Activity>(
                    data: activeActivities[index],
                    feedback: Material(
                      child: Container(
                        height: 100,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            activeActivities[index].name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Container(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        height: 100,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            activeActivities[index].name,
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
                          color: Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DragTarget<Activity>(
                          builder: (context, candidateData, rejectedData) {
                            return ListView.builder(
                              itemCount: beginActivities.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        beginActivities[index].name,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                        _formatDuration(beginActivities[index]
                                            .remainingTime),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          onAccept: (data) {
                            setState(() {
                              beginActivities.add(data);
                              availableActivities.removeWhere(
                                  (activity) => activity.name == data.name);
                              data.startCountdown(() {
                                setState(() {
                                  activeActivities.add(data);
                                  beginActivities.removeWhere(
                                      (activity) => activity.name == data.name);
                                });
                              }, (remainingTime) {
                                setState(() {});
                              });
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
                          color: Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DragTarget<Activity>(
                          builder: (context, candidateData, rejectedData) {
                            return ListView.builder(
                              itemCount: endActivities.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(
                                    endActivities[index].name,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              },
                            );
                          },
                          onAccept: (Activity data) {
                            setState(() {
                              endActivities.add(data);
                              activeActivities.removeWhere(
                                  (activity) => activity.name == data.name);
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
                  return LongPressDraggable<Activity>(
                    data: availableActivities[index],
                    feedback: Material(
                      child: Container(
                        height: 100,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.tealAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            availableActivities[index].name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Container(),
                    onDragCompleted: () {},
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
                          availableActivities[index].name,
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
