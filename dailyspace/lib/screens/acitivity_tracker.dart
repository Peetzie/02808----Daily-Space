import 'dart:developer';
import 'dart:async';
import 'package:dailyspace/custom_classes/taskinfo.dart';
import 'package:dailyspace/google/google_sign_in_manager.dart';
import 'package:dailyspace/google/google_services.dart';
import 'package:dailyspace/screens/login_screen.dart';
import 'package:dailyspace/screens/vis.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart'; // Import the intl package

import 'package:dailyspace/custom_classes/helper.dart';

class ActivityTracker extends StatefulWidget {
  const ActivityTracker({Key? key}) : super(key: key);

  @override
  _ActivityTrackerState createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends State<ActivityTracker> {
  late Map<String, TaskInfo> availableActivities;
  late Set<TaskInfo> activeActivities;
  Timer? _timer;
  late List<TaskInfo> earlyStartActivities;
  final GoogleSignInAccount? account =
      GoogleSignInManager.instance.googleSignIn.currentUser;

  late List<String> availableCalendars;
  Set<String> selectedCalendars = {};

  @override
  void initState() {
    super.initState();
    availableActivities = {};
    activeActivities = {};
    availableCalendars = [];
    earlyStartActivities = [];
    _fetchCalendars();
    _fetchActivities();

    // Update datetime every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCalendars() async {
    availableCalendars.clear();
    final calendars = await GoogleServices.fetchCalendars(account);
    setState(() {
      calendars.forEach((title, value) {
        log(title);
        availableCalendars.add(title);
      });
    });
  }

  Future<void> _fetchActivities() async {
    try {
      availableActivities.clear();
      earlyStartActivities.clear(); // Clear the earlyStartActivities list

      final tasks = await GoogleServices.fetchTasksFromCalendar(
          account, selectedCalendars);
      final now = DateTime.now();

      setState(() {
        tasks.values.forEach((task) {
          try {
            DateTime taskStart;
            if (task['start'].contains("T")) {
              // If the date format is 2024-04-11T11:05:48.576Z
              taskStart = DateTime.parse(task['start']);
              final difference = taskStart.difference(now).inMinutes;

              if (DateFormat('yyyy-MM-dd').format(taskStart) ==
                  DateFormat('yyyy-MM-dd').format(now)) {
                if (difference.abs() <= 30) {
                  // Add to earlyStartActivities if within 30 minutes
                  earlyStartActivities.add(TaskInfo(
                      task['taskId'],
                      task['title'],
                      task['start'],
                      task['end'],
                      task['colorId']));
                } else {
                  availableActivities[task['taskId']] =
                      availableActivities[task['taskId']] = TaskInfo(
                          task['taskId'],
                          task['title'],
                          task['start'],
                          task['end'],
                          task['colorId']);
                }
              } else {
                // Add to availableActivities if not today
                availableActivities[task['taskId']] = TaskInfo(task['taskId'],
                    task['title'], task['start'], task['end'], task['colorId']);
              }
            } else {
              // If the date format is 24-04-11
              taskStart = DateFormat('yy-MM-dd').parse(task['start']);
              if (DateFormat('yyyy-MM-dd').format(taskStart) ==
                  DateFormat('yyyy-MM-dd').format(now)) {
                earlyStartActivities.add(TaskInfo(task['taskId'], task['title'],
                    task['start'], task['end'], task['colorId']));
              } else {
                availableActivities[task['taskId']] = TaskInfo(task['taskId'],
                    task['title'], task['start'], task['end'], task['colorId']);
              }
            }
          } catch (e) {
            // Handle the error if the task['start'] is not in a valid DateTime format
            log("Error parsing date: ${e.toString()}");
          }
        });
      });

      log("List of available activities fetched on reload: $availableActivities");
    } catch (e) {
      // Handle potential errors from the fetch call
      log("Error fetching tasks: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildAvailableActivities(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildStartTask(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                  _buildWaitingToFinish(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateSelectedCalendars(Set<String> newSelectedCalendars) {
    setState(() {
      selectedCalendars = newSelectedCalendars;
    });
  }

  void _openCalendarOverlay() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CalendarOverlayDialog(
          availableCalendars: availableCalendars,
          selectedCalendars: selectedCalendars,
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          selectedCalendars = result as Set<String>;
        });
      }
    });
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      actions: [
        IconButton(
          onPressed: () async {
            await GoogleServices.createCalendars(account);
          },
          icon: const Icon(Icons.add),
          color: Colors.black,
          tooltip: "Create default calendar sortings",
        ),
        IconButton(
          onPressed: () async {
            _openCalendarOverlay();
          },
          icon: const Icon(Icons.calendar_month),
          color: Colors.black,
          tooltip: "Choose calendars to fetch events from",
        ),
        IconButton(
          onPressed: () async {
            log("Resyncing");
            await _fetchActivities();
          },
          tooltip: "Sync with Google",
          icon: const Icon(Icons.sync),
          color: Colors.black,
        ),
        IconButton(
          onPressed: () async {
            await GoogleSignInManager.instance.googleSignIn.signOut();
            // Navigate back to login screen
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()));
          },
          icon: const Icon(Icons.logout),
          color: Colors.black,
        )
      ],
    );
  }

  Stream<DateTime> currentTimeStream() async* {
    while (true) {
      await Future.delayed(Duration(seconds: 1));
      yield DateTime.now();
    }
  }

  Widget _buildAvailableActivities() {
    double maxHeight = MediaQuery.of(context).size.height * 0.13;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.08,
            vertical: MediaQuery.of(context).size.width * 0.04,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Available Activities',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Text(
                _getFormattedDate(),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.018,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: maxHeight,
          child: Container(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableActivities.length,
              itemBuilder: (context, index) {
                final task = availableActivities.values.elementAt(index);

                return _buildTaskContainer(
                    task.title, task.start, task.colorId);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getFormattedDate() {
    DateTime now = DateTime.now();
    DateFormat dateFormat = DateFormat('EEEE, dd/MM HH:mm:ss');
    return dateFormat.format(now);
  }

  Widget _buildTaskContainer(String title, String? start, String colorId) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.15,
      width: MediaQuery.of(context).size.width * 0.15,
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.02,
      ),
      decoration: BoxDecoration(
        color: getColorFromId(colorId),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: MediaQuery.of(context).size.width * 0.03,
              ),
            ),
            if (start != "") // Check if start date is not empty
              Text(
                TimeFormatter.formatTime(start),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: MediaQuery.of(context).size.width * 0.02,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartTask() {
    double height = MediaQuery.of(context).size.height * 0.25;
    double width = MediaQuery.of(context).size.width * 0.9;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: EdgeInsets.all(width * 0.05),
      child: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Start Task',
                  style: TextStyle(
                    fontSize: height * 0.08,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.005,
                ),
                Text(
                  'It is time to start this task',
                  style: TextStyle(fontSize: height * 0.04),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.02),
          Flexible(
            child: ListView.builder(
              itemCount: earlyStartActivities.length,
              itemBuilder: (context, index) {
                final task = earlyStartActivities[index];
                String? startTime = task.start;
                String colorId = task.colorId;
                return Container(
                  margin: EdgeInsets.symmetric(
                    vertical: height * 0.01,
                  ),
                  decoration: BoxDecoration(
                      color: getColorFromId(colorId),
                      borderRadius: BorderRadius.circular(
                        width * 0.01,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: width * 0.02,
                            offset: Offset(0, 2))
                      ]),
                  child: ListTile(
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: height * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: height * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  // Add functionality for the first button
                },
                child: Text('Button 1'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Add functionality for the second button
                },
                child: Text('Button 2'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingToFinish() {
    double containerHeight = MediaQuery.of(context).size.height * 0.25;
    double containerWidth = MediaQuery.of(context).size.width * 0.9;

    return Container(
      width: containerWidth,
      height: containerHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: EdgeInsets.all(
        containerWidth * 0.05,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Waiting to finish',
            style: TextStyle(
              fontSize: containerHeight * 0.08,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Only display this task if activeActivities is empty
          if (activeActivities.isEmpty) ...[
            SizedBox(height: containerWidth * 0.05),
            Container(
              alignment: Alignment.center,
              child: Text(
                "Not yet, keep it up",
                style: TextStyle(
                  fontSize: containerHeight * 0.04,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CalendarOverlayDialog extends StatefulWidget {
  final List<String> availableCalendars;
  final Set<String> selectedCalendars;

  const CalendarOverlayDialog({
    Key? key,
    required this.availableCalendars,
    required this.selectedCalendars,
  }) : super(key: key);

  @override
  _CalendarOverlayDialogState createState() => _CalendarOverlayDialogState();
}

class _CalendarOverlayDialogState extends State<CalendarOverlayDialog> {
  Set<String>? _newSelectedCalendars;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Calendar'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: widget.availableCalendars.length,
          itemBuilder: (context, index) {
            final calendarKey = widget.availableCalendars[index];
            return CheckboxListTile(
              title: Text(calendarKey),
              value: widget.selectedCalendars.contains(calendarKey),
              onChanged: (bool? value) {
                setState(() {
                  if (value != null) {
                    if (value) {
                      widget.selectedCalendars.add(calendarKey);
                    } else {
                      widget.selectedCalendars.remove(calendarKey);
                    }
                  }
                });
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            _newSelectedCalendars = widget.selectedCalendars;
            Navigator.of(context).pop(_newSelectedCalendars);
          },
          child: Text('OK'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _newSelectedCalendars = widget.selectedCalendars;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _newSelectedCalendars = widget.selectedCalendars;
  }

  @override
  void didUpdateWidget(CalendarOverlayDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    _newSelectedCalendars = widget.selectedCalendars;
  }

  @override
  void setState(VoidCallback fn) {
    _newSelectedCalendars = widget.selectedCalendars;
    super.setState(fn);
  }
}
