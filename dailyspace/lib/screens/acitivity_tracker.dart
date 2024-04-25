import 'dart:developer';
import 'dart:async';
import 'package:dailyspace/datastructures/firebase_event.dart';
import 'package:dailyspace/datastructures/taskinfo.dart';
import 'package:dailyspace/services/firebase_handler.dart';
import 'package:dailyspace/services/google_sign_in_manager.dart';
import 'package:dailyspace/services/google_services.dart';
import 'package:dailyspace/sources/palette.dart';
import 'package:dailyspace/screens/login_screen.dart';
import 'package:dailyspace/screens/vis.dart';
import 'package:dailyspace/widgets/activity_tracker/add_calendar.dart';
import 'package:dailyspace/widgets/activity_tracker/calendar_overlay.dart';
import 'package:dailyspace/widgets/activity_tracker/reason_dialog.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dailyspace/datastructures/Timeformatter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dailyspace/widgets/activity_tracker/activity_manager.dart';

class ActivityTracker extends StatefulWidget {
  const ActivityTracker({Key? key}) : super(key: key);

  @override
  _ActivityTrackerState createState() => _ActivityTrackerState();
}

final FirebaseManager firebaseManager = FirebaseManager();

class _ActivityTrackerState extends State<ActivityTracker> {
  GoogleSignInAccount? account;
  late Map<String, TaskInfo> availableActivities;
  late Set<FirebaseEvent> activeActivities;
  Timer? _timer;
  late Set<TaskInfo> earlyStartActivities;
  Set<String> selectedTaskIds = Set<String>();

  late List<String> availableCalendars;
  Set<String> selectedCalendars = {};

  @override
  void initState() {
    super.initState();
    availableActivities = {};
    activeActivities = {};
    availableCalendars = [];
    earlyStartActivities = {};
    _initAccountAndFetchData();

    // Update datetime every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  void _initAccountAndFetchData() async {
    account = GoogleSignInManager.instance.currentUser;
    account ??= await GoogleSignInManager.instance.signIn();
    if (account != null) {
      await _fetchCalendars();
      await _fetchAndLogCalendars(); // Wait for _fetchAndLogCalendars() to complete
      await _fetchActivities(); // Now call _fetchActivities() after _fetchAndLogCalendars() finishes
      _fetchActiveEvents();
    } else {
      // Handle the scenario where sign-in failed or was declined
      debugPrint("Google sign-in failed or was declined by the user.");
    }
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
        availableCalendars.add(title);
      });
    });
  }

  Future<void> _fetchActivities() async {
    try {
      availableActivities.clear();
      earlyStartActivities.clear();
      // Fetch active tasks from Firebase
      Map<String, FirebaseEvent> firebaseTasks =
          await firebaseManager.fetchActiveEvents();
      Set<String> endedFirebaseTasksIds =
          await firebaseManager.fetchAllEndedEventIds();
      Map<String, FirebaseEvent> firebaseDelayedTasks =
          await firebaseManager.fetchDelayedEvents();
      final tasks = await GoogleServices.fetchTasksFromCalendar(
          account, selectedCalendars);
      log(tasks.toString());
      final now = DateTime.now();

      setState(() {
        tasks.values.forEach((task) {
          TaskInfo newTask = TaskInfo(task['taskId'], task['calendarName'],
              task['title'], task['start'], task['end'], task['colorId']);

          DateTime taskStart;
          int difference;

          // Check if the task is already active or ended, skip if it is
          if (!firebaseTasks.containsKey(task['taskId']) &&
              !endedFirebaseTasksIds.contains(task['taskId'])) {
            handleTaskTiming(task, now, newTask);
          }
        });

        // Handle delayed tasks
        firebaseDelayedTasks.values.forEach((delayedTask) {
          TaskInfo newTask = TaskInfo(
              delayedTask.taskId,
              delayedTask.calendarName,
              delayedTask.taskTitle,
              delayedTask.delay?.last,
              delayedTask.endTime,
              delayedTask.colorId);
          DateTime taskStart = DateTime.parse(delayedTask.delay!.last);
          int difference = now.difference(taskStart).inMinutes;

          if (DateFormat('yyyy-MM-dd').format(taskStart) ==
              DateFormat('yyyy-MM-dd').format(now)) {
            if (difference.abs() <= 30) {
              earlyStartActivities.add(newTask);
            } else {
              availableActivities[delayedTask.taskId] = newTask;
            }
          } else {
            availableActivities[delayedTask.taskId] = newTask;
          }
        });

        earlyStartActivities.removeWhere(
            (task) => availableActivities.containsKey(task.taskId));

        log("Updated lists of activities based on current statuses.");
      });
    } catch (e) {
      log("Error fetching tasks: ${e.toString()}");
    }
  }

  void handleTaskTiming(
      Map<String, dynamic> task, DateTime now, TaskInfo newTask) {
    DateTime taskStart;
    int difference;
    if (task['start'].contains("T")) {
      // Time-specific task start
      taskStart = DateTime.parse(task['start']);
      difference = taskStart.difference(now).inMinutes;
    } else {
      // Full-day or date-only event
      try {
        taskStart = DateFormat('yyyy-MM-dd').parse(task['start']);
        difference = now.difference(taskStart).inMinutes;
      } catch (e) {
        log("Error parsing date-only start: ${e.toString()}");
        return; // Skip this iteration on parse error
      }

      // Special handling for full-day tasks that start today
      if (DateFormat('yyyy-MM-dd').format(taskStart) ==
          DateFormat('yyyy-MM-dd').format(now)) {
        earlyStartActivities.add(newTask);
        return; // Add to start today and skip further checks
      }
    }

    // Regular checks for tasks with specific times
    if (DateFormat('yyyy-MM-dd').format(taskStart) ==
        DateFormat('yyyy-MM-dd').format(now)) {
      if (difference.abs() <= 30) {
        earlyStartActivities.add(newTask);
      } else {
        availableActivities[task['taskId']] = newTask;
      }
    } else {
      availableActivities[task['taskId']] = newTask;
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
            await GoogleSignInManager.instance.signOut();
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

                return _buildTaskContainer(task);
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

  Widget _buildTaskContainer(TaskInfo task) {
    bool isOverdue = task.start != null &&
        DateTime.parse(task.start!).isBefore(DateTime.now());

    return LongPressDraggable<TaskInfo>(
      data: task,
      feedback: Material(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.width * 0.2,
          decoration: BoxDecoration(
            color: getColorFromId(task.colorId),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              task.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.038,
              ),
            ),
          ),
        ),
        elevation: 4.0,
        color:
            Colors.transparent, // Make sure the Material widget is transparent
      ),
      onDragStarted: () {
        // Actions to perform when dragging starts
      },
      childWhenDragging: Container(
        width: MediaQuery.of(context).size.width * 0.23,
        height: MediaQuery.of(context).size.width * 0.23,
        decoration: BoxDecoration(
          color:
              Colors.transparent, // Maintain the space, but make it invisible
          shape: BoxShape.circle,
        ),
      ),
      child: Container(
        // Ensure this is the only 'child' property in this widget
        height: MediaQuery.of(context).size.width * 0.23,
        width: MediaQuery.of(context).size.width * 0.23,
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.02,
        ),
        decoration: BoxDecoration(
          color: getColorFromId(task.colorId),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  task.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: MediaQuery.of(context).size.width * 0.038,
                  ),
                ),
                if (task.start != null)
                  Text(
                    TimeFormatter.formatTime(task.start),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                    ),
                  ),
              ],
            ),
            if (isOverdue)
              Positioned(
                right: MediaQuery.of(context).size.width *
                    0.03, // Adjust position to overlap the border
                bottom: -MediaQuery.of(context).size.width *
                    0.01, // Adjust position to overlap the border
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Icon(
                    Icons.alarm,
                    size: MediaQuery.of(context).size.width * 0.04,
                    color: Colors.white,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildStartTask() {
    double height = MediaQuery.of(context).size.height * 0.25;
    double width = MediaQuery.of(context).size.width * 0.9;

    return DragTarget<TaskInfo>(
      onAccept: (TaskInfo task) {
        setState(() {
          earlyStartActivities.add(task);
          availableActivities.remove(task.taskId);
        });
      },
      builder: (context, candidateData, rejectedData) {
        bool areButtonsEnabled = selectedTaskIds.isNotEmpty;
        bool laterEnabled = (selectedTaskIds.length == 1);
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: EdgeInsets.all(width * 0.035),
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
                      style: TextStyle(fontSize: height * 0.07),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * 0.02),
              Expanded(
                child: earlyStartActivities.isEmpty
                    ? Center(child: Text("No tasks are about to start."))
                    : ListView.builder(
                        itemCount: earlyStartActivities.length,
                        itemBuilder: (context, index) {
                          final task = earlyStartActivities.elementAt(index);
                          bool isSelected =
                              selectedTaskIds.contains(task.taskId);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedTaskIds.remove(task.taskId);
                                } else {
                                  selectedTaskIds.add(task.taskId);
                                }
                              });
                            },
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.03,
                              margin: EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 2.0),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue[300]
                                    : getColorFromId(task.colorId),
                                borderRadius: BorderRadius.circular(2),
                                border:
                                    Border.all(color: Colors.black54, width: 1),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: width * 0.04),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      calculateDuration(task.start, task.end),
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: width * 0.04),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
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
                    onPressed: areButtonsEnabled
                        ? () {
                            setState(() {
                              earlyStartActivities.forEach((task) {
                                if (selectedTaskIds.contains(task.taskId)) {
                                  DateTime now = DateTime.now();
                                  String formattedTimeStampWithTimeZone =
                                      DateFormat("yyyy-MM-ddTHH:mm:ss").format(
                                          now); // Format without milliseconds and with timezone
                                  String timezoneOffset = now
                                              .timeZoneOffset.inHours >
                                          0
                                      ? "+${now.timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:00"
                                      : "-${now.timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:00"; // Calculate timezone offset
                                  formattedTimeStampWithTimeZone +=
                                      timezoneOffset;
                                  FirebaseEvent event =
                                      FirebaseEvent.fromTaskInfo(
                                          task,
                                          formattedTimeStampWithTimeZone,
                                          null,
                                          null,
                                          null,
                                          null);
                                  firebaseManager.addFirebaseEvent(event);
                                  activeActivities.add(event);
                                }
                              });
                              earlyStartActivities.removeWhere((task) =>
                                  selectedTaskIds.contains(task.taskId));
                              selectedTaskIds.clear();
                            });
                          }
                        : null,
                    child: Text('Start Now!'),
                  ),
                  ElevatedButton(
                    onPressed: areButtonsEnabled && laterEnabled
                        ? () async {
                            var delayResult = await reasonDialog(context);
                            if (delayResult != null) {
                              String reason = delayResult['reason'];
                              String delay =
                                  TimeFormatter.convertDurationToISO8601(
                                      delayResult['delay']);

                              // only one can be selected so we can use first element of selected as identifier.
                              if (selectedTaskIds.isNotEmpty) {
                                log(reason);
                                String selectedTaskId = selectedTaskIds.first;
                                TaskInfo selectedTask =
                                    earlyStartActivities.firstWhere((task) =>
                                        task.taskId == selectedTaskId);
                                if (selectedTask != null) {
                                  FirebaseEvent? existingEvent =
                                      await firebaseManager
                                          .fetchDelayedEvent(selectedTaskId);
                                  if (existingEvent != null) {
                                    existingEvent.reasons?.add(reason);
                                    existingEvent.delay?.add(delay);

                                    // updatie existing event
                                    await firebaseManager.updateDelayedEvent(
                                        selectedTaskId, existingEvent);
                                  } else {
                                    List<String> reasons = [];
                                    List<String> delays = [];
                                    reasons.add(reason);
                                    delays.add(delay);

                                    FirebaseEvent newDelayedEvent =
                                        FirebaseEvent.fromTaskInfo(selectedTask,
                                            null, null, null, reasons, delays);
                                    firebaseManager
                                        .addDelayedEvent(newDelayedEvent);
                                    earlyStartActivities.remove(selectedTaskId);
                                    ;
                                  }
                                }
                              }
                            }
                          }
                        : null,
                    child: Text('Later'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _endEvent(FirebaseEvent event) async {
    try {
      await firebaseManager.endEvent(event.taskId.toString());
      _fetchActiveEvents();
    } catch (e) {
      debugPrint('Error ending event: ${e.toString()}');
    }
  }

  void _fetchActiveEvents() async {
    try {
      var activeEventsMap = await firebaseManager.fetchActiveEvents();
      var activeEvents = activeEventsMap.values.toSet();
      setState(() {
        activeActivities = activeEvents;
      });
    } catch (e) {
      debugPrint('Error fetching active events: ${e.toString()}');
    }
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
          // Only display this task if activeActivities is not empty
          Expanded(
              child: ListView.builder(
            itemCount: activeActivities.length,
            itemBuilder: (context, index) {
              FirebaseEvent event = activeActivities.elementAt(index);
              DateTime? startedDateTime =
                  DateTime.tryParse(event.startedAt ?? '');
              String formattedDate = startedDateTime != null
                  ? DateFormat('yyyy-MM-dd – kk:mm').format(startedDateTime)
                  : 'Date not available';
              return ListTile(
                title: Text(event.taskTitle),
                subtitle: Text('Started at $formattedDate'),
                trailing: ElevatedButton(
                  onPressed: () => _endEvent(event),
                  child: Text('Finish'),
                ),
              );
            },
          )),
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

  String calculateDuration(String? start, String? end) {
    if (start == null || end == null) {
      return 'Duration Unknown';
    }
    DateTime startTime = DateTime.parse(start);
    DateTime endTime = DateTime.parse(end);
    Duration duration = endTime.difference(startTime);
    return "${duration.inHours}h ${duration.inMinutes % 60}m";
  }

  Future<void> _fetchAndLogCalendars() async {
    try {
      selectedCalendars = await FirebaseManager().fetchSelectedCalendars();
      // Now `selectedCalendars` is populated with the fetched data
    } catch (e) {
      log("Error fetching calendars: $e");
    }
  }
}
