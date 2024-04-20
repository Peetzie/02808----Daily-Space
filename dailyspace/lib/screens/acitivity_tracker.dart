import 'dart:developer';
import 'dart:async';
import 'package:dailyspace/custom_classes/firebase_event.dart';
import 'package:dailyspace/custom_classes/taskinfo.dart';
import 'package:dailyspace/google/firebase_handler.dart';
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
      _fetchActivities(); // Now call _fetchActivities() after _fetchAndLogCalendars() finishes
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
        log(title);
        availableCalendars.add(title);
      });
    });
  }

  Future<void> _fetchActivities() async {
    try {
      // Fetch active tasks from Firebase
      Map<String, FirebaseEvent> firebaseTasks =
          await firebaseManager.fetchActiveEvents();

      availableActivities.clear();
      earlyStartActivities.clear();

      final tasks = await GoogleServices.fetchTasksFromCalendar(
          account, selectedCalendars);
      final now = DateTime.now();

      setState(() {
        tasks.values.forEach((task) {
          TaskInfo newTask = TaskInfo(task['taskId'], task['title'],
              task['start'], task['end'], task['colorId']);

          DateTime taskStart;
          int difference;

          // Check if the task is already active, skip if it is
          if (!firebaseTasks.containsKey(task['taskId'])) {
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
        });
      });

      log("Updated lists of activities based on current statuses.");
    } catch (e) {
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
    // Determine if the task is overdue
    bool isOverdue =
        start != null && DateTime.parse(start).isBefore(DateTime.now());

    return Container(
      height: MediaQuery.of(context).size.width * 0.23,
      width: MediaQuery.of(context).size.width * 0.23,
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.02,
      ),
      decoration: BoxDecoration(
        color: getColorFromId(colorId),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior:
            Clip.none, // Allow children to be rendered outside the container
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: MediaQuery.of(context).size.width * 0.038,
                ),
              ),
              if (start != null &&
                  start != "") // Check if start date is not empty
                Text(
                  TimeFormatter.formatTime(start),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                  ),
                ),
            ],
          ),
          // Overlay the badge at the bottom right if the task is overdue
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
            ),
        ],
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
                    onPressed: () {
                      setState(() {
                        earlyStartActivities.forEach((task) {
                          if (selectedTaskIds.contains(task.taskId)) {
                            DateTime now = DateTime.now();
                            String formattedTimeStamp =
                                DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
                            FirebaseEvent event = FirebaseEvent.fromTaskInfo(
                                task, now, null, null);
                            firebaseManager.addFirebaseEvent(event);
                            activeActivities.add(event);
                          }
                        });
                        earlyStartActivities.removeWhere(
                            (task) => selectedTaskIds.contains(task.taskId));
                        selectedTaskIds.clear();
                      });
                    },
                    child: Text('Start Now!'),
                  ),
                  ElevatedButton(
                    onPressed: () async {},
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
      var activeEvents = await firebaseManager.fetchActiveEvents();
      setState(() {
        activeEvents = activeEvents;
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
          // Only display this task if activeActivities is empty
          Expanded(
              child: ListView.builder(
            itemCount: activeActivities.length,
            itemBuilder: (context, index) {
              FirebaseEvent event = activeActivities.elementAt(index);
              return ListTile(
                title: Text(event.taskTitle),
                subtitle: Text('Started at ${event.startedAt}'),
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
      log("Selected calendars on page load: ${selectedCalendars.toString()}");
    } catch (e) {
      log("Error fetching calendars: $e");
    }
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
    double width = MediaQuery.of(context).size.width * 0.8;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select Calendar(s)',
            style:
                TextStyle(fontSize: width * 0.06, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              _fetchCalendars();
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _openAddCalendarOverlay();
            },
          ),
        ],
      ),
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
          onPressed: () async {
            _newSelectedCalendars = widget.selectedCalendars;
            await firebaseManager.saveSelectedCalendars(_newSelectedCalendars!);
            Navigator.of(context).pop(_newSelectedCalendars);
          },
          child: Text('OK'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_newSelectedCalendars);
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }

  void _openAddCalendarOverlay() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCalendarOverlay();
      },
    );
  }

  Future<void> _fetchCalendars() async {
    GoogleSignInAccount? account = GoogleSignInManager.instance.currentUser;
    try {
      // Fetch new calendars
      final calendars = await GoogleServices.fetchCalendars(account);
      setState(() {
        // Update available calendars
        widget.availableCalendars.clear();
        calendars.forEach((title, value) {
          widget.availableCalendars.add(title);
        });
      });
    } catch (e) {
      // Handle potential errors from the fetch call
      print("Error fetching calendars: $e");
    }
  }

  void _updateSelectedCalendars() {
    // Implement the logic to update selected calendars here
    setState(() {
      // Update the selected calendars
      _newSelectedCalendars = widget.selectedCalendars;
    });
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

class AddCalendarOverlay extends StatefulWidget {
  final Map<String, int> calendarData = {
    'Food + nutrition': 7,
    'Fitness': 4,
    'Office Work': 9,
    'Personal Time': 16,
    'Family': 24,
    'Mindfulness': 16,
    'Rest + travel': 1,
    'Digital life': 8,
  };

  AddCalendarOverlay({Key? key}) : super(key: key);

  @override
  _AddCalendarOverlayState createState() => _AddCalendarOverlayState();
}

class _AddCalendarOverlayState extends State<AddCalendarOverlay> {
  Map<String, String> _selectedColors = {};
  Map<String, bool> _selectedCalendars = {};
  bool _isLoading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.calendarData.forEach((calendarName, colorId) {
      _selectedColors[calendarName] = 'Color $colorId';
      _selectedCalendars[calendarName] = false; // Initialize all as unselected
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Calendar'),
      content: _isLoading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                LinearProgressIndicator(value: _progress), // Progress bar
                SizedBox(height: 20),
                Text('${(_progress * 100).toStringAsFixed(0)}% completed'),
              ],
            )
          : buildContent(),
      actions: !_isLoading
          ? <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: createCalendars,
                child: Text('OK'),
              ),
            ]
          : null,
    );
  }

  Widget buildContent() {
    return SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.calendarData.length,
        itemBuilder: (BuildContext context, int index) {
          final calendarName = widget.calendarData.keys.elementAt(index);
          final selectedColor = _selectedColors[calendarName]!;
          final isSelected = _selectedCalendars[calendarName] ?? false;

          return Row(
            children: [
              DropdownButton<String>(
                value: selectedColor,
                onChanged: (newValue) {
                  setState(() {
                    _selectedColors[calendarName] = newValue!;
                  });
                },
                items: _buildColorDropdownItems(selectedColor),
              ),
              Expanded(child: Text(calendarName)),
              Checkbox(
                value: isSelected,
                onChanged: (bool? newValue) {
                  setState(() {
                    _selectedCalendars[calendarName] = newValue!;
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildColorDropdownItems(String currentColor) {
    List<String> usedColors = _selectedColors.values.toList();
    List<DropdownMenuItem<String>> items = [];

    for (int i = 1; i <= 24; i++) {
      String colorValue = 'Color $i';
      if (!usedColors.contains(colorValue) || colorValue == currentColor) {
        items.add(DropdownMenuItem(
          value: colorValue,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: getColorFromId(i.toString()),
                radius: 8,
              ),
              SizedBox(width: 8),
            ],
          ),
        ));
      }
    }

    return items;
  }

  Future<void> createCalendars() async {
    GoogleSignInAccount? account = GoogleSignInManager.instance.currentUser;
    setState(() => _isLoading = true);
    _progress = 0.0; // Initialize progress

    final selectedCalendarsWithColors = getSelectedCalendarsWithColors();
    final total = selectedCalendarsWithColors.length;
    var completed = 0;

    for (var entry in selectedCalendarsWithColors.entries) {
      Map<String, int> calendarInfo = {};
      calendarInfo[entry.key] = entry.value;
      await GoogleServices.createCalendar(account, calendarInfo);
      completed++;
      setState(() {
        _progress = completed / total;
      });
    }

    setState(() => _isLoading = false);
    Navigator.of(context)
        .pop(); // Optionally, close the dialog or navigate after completion
  }

  Map<String, int> getSelectedCalendarsWithColors() {
    Map<String, int> selectedCalendarsWithColors = {};
    _selectedCalendars.forEach((key, value) {
      if (value) {
        final colorId =
            int.parse(_selectedColors[key]!.replaceAll('Color ', ''));
        selectedCalendarsWithColors[key] = colorId;
      }
    });

    return selectedCalendarsWithColors;
  }
}
