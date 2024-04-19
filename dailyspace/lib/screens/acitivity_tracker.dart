import 'dart:developer';
import 'dart:async';
import 'package:dailyspace/custom_classes/taskinfo.dart';
import 'package:dailyspace/google/google_sign_in_manager.dart';
import 'package:dailyspace/google/google_services.dart';
import 'package:dailyspace/main.dart';
import 'package:dailyspace/screens/vis.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:dailyspace/activity_manager.dart';
import 'package:dailyspace/custom_classes/helper.dart';
import 'package:provider/provider.dart';

class ActivityTracker extends StatefulWidget {
  const ActivityTracker({Key? key}) : super(key: key);

  @override
  _ActivityTrackerState createState() => _ActivityTrackerState();
}

final GoogleSignInAccount? account =
    GoogleSignInManager.instance.googleSignIn.currentUser;

class _ActivityTrackerState extends State<ActivityTracker> {
  late Map<String, TaskInfo> availableActivities;
  late Set<TaskInfo> activeActivities;
  late Set<TaskInfo> endedActivities;
  Timer? _timer;
  late List<TaskInfo> earlyStartActivities;

  String calculateDuration(String? start, String? end) {
    if (start == null || end == null) {
      return 'Duration Unknown';
    }
    DateTime startTime = DateTime.parse(start);
    DateTime endTime = DateTime.parse(end);
    Duration duration = endTime.difference(startTime);
    return "${duration.inHours}h ${duration.inMinutes % 60}m";
  }

  int calculateCountdown(String? end) {
    if (end == null) {
      return 0;
    }
    DateTime endTime = DateTime.parse(end);
    Duration remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inMinutes;
  }

  late List<String> availableCalendars;
  Set<String> selectedCalendars = {};

  int _counter = 0;

  @override
  void initState() {
    super.initState();
    availableActivities = {};
    activeActivities = {};
    endedActivities = {};
    availableCalendars = [];
    earlyStartActivities = [];
    _fetchCalendars();
    _fetchActivities();

    if (availableActivities.isNotEmpty) {
      String? endTime = availableActivities
          .values.first.end; // Assuming there is at least one activity
      _counter = calculateCountdown(endTime);
    }
    // Update datetime every minute
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (_counter > 0) {
        _counter--;
      } else {
        _timer?.cancel();
      }
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
      Provider.of<ActivityManager>(context, listen: false)
          .setAvailableActivities(availableActivities);
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                  _buildStartTask(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                  _buildWaitingToFinish(),
                  _buildEndedTask(),
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
            await GoogleSignInManager.instance.googleSignIn.signOut();
            // Navigate back to login screen
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainScreen()));
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
    double maxHeight = MediaQuery.of(context).size.height * 0.1;

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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: availableActivities.length,
            itemBuilder: (context, index) {
              final task = availableActivities.values.elementAt(index);
              return LongPressDraggable<TaskInfo>(
                data: task,
                child:
                    _buildTaskContainer(task.title, task.start, task.colorId),
                feedback: Material(
                  child:
                      _buildTaskContainer(task.title, task.start, task.colorId),
                ),
                childWhenDragging: Container(),
              );
            },
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
      height: MediaQuery.of(context).size.width * 0.1,
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
              SizedBox(height: height * 0.015),
              Flexible(
                child: ListView.builder(
                  itemCount: earlyStartActivities.length,
                  itemBuilder: (context, index) {
                    final task = earlyStartActivities[index];
                    String? startTime = task.start;
                    String colorId = task.colorId;
                    String duration = calculateDuration(task.start, task.end);
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
                          "${task.title} - $duration",
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
                      setState(() {
                        activeActivities.addAll(Set.from(earlyStartActivities));
                        earlyStartActivities.clear();
                      });
                    },
                    child: Text('Start Now!'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _showStartLaterDialog(context);
                    },
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

  void _showStartLaterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Why do you want to start later?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Reason',
                    suffixIcon: Icon(Icons.close),
                  ),
                ),
                ListTile(title: Text('Menu item')),
                ListTile(title: Text('Menu item')),
                ListTile(title: Text('Menu item')),
                ListTile(title: Text('Menu item')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaitingToFinish() {
    double containerHeight = MediaQuery.of(context).size.height * 0.15;
    double containerWidth = MediaQuery.of(context).size.width * 0.9;

    return Container(
      width: containerWidth,
      height: containerHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: EdgeInsets.all(containerWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Waiting to finish',
            style: TextStyle(
              fontSize: containerHeight * 0.1,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: activeActivities.length,
              itemBuilder: (context, index) {
                TaskInfo task = activeActivities.elementAt(index);
                return buildTaskItem(task, "$_counter");
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndedTask() {
    double containerHeight = MediaQuery.of(context).size.height * 0.15;
    double containerWidth = MediaQuery.of(context).size.width * 0.9;
    double verticalSpacing = MediaQuery.of(context).size.height * 0.06;
    return Container(
      height: containerHeight,
      width: containerWidth,
      margin: EdgeInsets.symmetric(
        vertical: verticalSpacing,
      ),
      padding: EdgeInsets.all(containerWidth * 0.05),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Ended Task',
          style: TextStyle(
            fontSize: containerHeight * 0.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: endedActivities.length,
            itemBuilder: (context, index) {
              TaskInfo task = endedActivities.elementAt(index);
              return ListTile(
                title: Text(task.title),
                trailing: Icon(Icons.check, color: Colors.green),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget buildTaskItem(TaskInfo task, String countdown) {
    double containerHeight = MediaQuery.of(context).size.height * 0.15;
    double containerWidth = MediaQuery.of(context).size.width * 0.9;
    double taskContainerWidth = containerWidth * 0.35;

    int hours = _counter ~/ 60;
    int minutes = _counter % 60;
    String formattedCountdown =
        "${hours}h ${minutes.toString().padLeft(2, '0')}m";

    return Row(
      children: [
        Container(
          width: taskContainerWidth,
          margin: EdgeInsets.symmetric(
            vertical: containerHeight * 0.01,
          ),
          decoration: BoxDecoration(
              color: getColorFromId(task.colorId),
              borderRadius: BorderRadius.circular(containerWidth * 0.01),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: containerWidth * 0.02,
                    offset: Offset(0, 2))
              ]),
          child: ListTile(
            title: Text(
              "${task.title} - $formattedCountdown",
              style: TextStyle(
                fontSize: containerHeight * 0.08,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    activeActivities.remove(task);
                    endedActivities.add(task);
                  });
                },
                child: Text('Finished'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showDelayDialog(context);
                  });
                },
                child: Text('Delay'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color.fromARGB(255, 91, 91, 91),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  void _showDelayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Why do you want to delay?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Reason',
                    suffixIcon: Icon(Icons.search),
                  ),
                ),
                ListTile(title: Text('Menu item')),
                ListTile(title: Text('Menu item')),
                ListTile(title: Text('Menu item')),
                ListTile(title: Text('Menu item')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
          onPressed: () {
            _newSelectedCalendars = widget.selectedCalendars;
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
