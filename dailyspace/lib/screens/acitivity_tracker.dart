import 'dart:developer';
import 'dart:async';
import 'package:dailyspace/datastructures/calendar_manager.dart';
import 'package:dailyspace/datastructures/data_manager.dart';
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
import 'package:dailyspace/widgets/loading_snackbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dailyspace/datastructures/Timeformatter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:dailyspace/widgets/activity_tracker/activity_manager.dart';

class ActivityTracker extends StatefulWidget {
  final CalendarManager calendarManager;
  final dataManager;
  const ActivityTracker(
      {Key? key, required this.calendarManager, required this.dataManager})
      : super(key: key);

  @override
  _ActivityTrackerState createState() => _ActivityTrackerState();
}

final FirebaseManager firebaseManager = FirebaseManager();

class _ActivityTrackerState extends State<ActivityTracker> {
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2), // Adjust the duration as needed
      ),
    );
  }

  GoogleSignInAccount? account;
  late CalendarManager calendarManager;
  late DataManager dataManager;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    calendarManager = widget.calendarManager;
    dataManager = widget.dataManager;
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
      showLoadingSnackbar(context);
      await dataManager.fetchAndStoreActivities(
          account); // Now call _fetchActivities() after _fetchAndLogCalendars() finishes
      log("activity test" + dataManager.activeActivities.toString());
      log("Testing");
      log(dataManager.availableActivities.toString());
      // Dismiss loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildAvailableActivities(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildStartTask(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  _buildWaitingToFinish(),
                ],
              ),
            ),
          ),
        ],
      ),
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
                TimeFormatter.getFormattedDate(),
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
              itemCount: dataManager.availableActivities.length,
              itemBuilder: (context, index) {
                final task =
                    dataManager.availableActivities.values.elementAt(index);

                return _buildTaskContainer(task);
              },
            ),
          ),
        ),
      ],
    );
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
          dataManager.earlyStartActivities.add(task);
          dataManager.availableActivities.remove(task.taskId);
        });
      },
      builder: (context, candidateData, rejectedData) {
        bool areButtonsEnabled = dataManager.selectedTaskIds.isNotEmpty;
        bool laterEnabled = (dataManager.selectedTaskIds.length == 1);
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
                child: dataManager.earlyStartActivities.isEmpty
                    ? Center(child: Text("No tasks are about to start."))
                    : ListView.builder(
                        itemCount: dataManager.earlyStartActivities.length,
                        itemBuilder: (context, index) {
                          final task =
                              dataManager.earlyStartActivities.elementAt(index);
                          bool isSelected =
                              dataManager.selectedTaskIds.contains(task.taskId);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  dataManager.selectedTaskIds
                                      .remove(task.taskId);
                                } else {
                                  dataManager.selectedTaskIds.add(task.taskId);
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
                                      TimeFormatter.calculateDurationString(
                                          task.start, task.end),
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
                              dataManager.earlyStartActivities.forEach((task) {
                                if (dataManager.selectedTaskIds
                                    .contains(task.taskId)) {
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
                                  dataManager.activeActivities.add(event);
                                }
                              });
                              dataManager.earlyStartActivities.removeWhere(
                                  (task) => dataManager.selectedTaskIds
                                      .contains(task.taskId));
                              dataManager.selectedTaskIds.clear();
                              _showSnackbar("Task started successfully");
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
                              if (dataManager.selectedTaskIds.isNotEmpty) {
                                log(reason);
                                String selectedTaskId =
                                    dataManager.selectedTaskIds.first;
                                TaskInfo selectedTask = dataManager
                                    .earlyStartActivities
                                    .firstWhere((task) =>
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
                                    _showSnackbar(
                                        "Successfully postponed event");
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

                                    dataManager.earlyStartActivities
                                        .remove(selectedTaskId);
                                    _showSnackbar(
                                        "Successfully postponed event");
                                  }
                                }
                              }
                            }
                          }
                        : null,
                    child: Text('Postpone '),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
          // Only display this task if activeActivities is not empty
          Expanded(
              child: ListView.builder(
            itemCount: dataManager.activeActivities.length,
            itemBuilder: (context, index) {
              FirebaseEvent event =
                  dataManager.activeActivities.elementAt(index);
              DateTime? startedDateTime =
                  DateTime.tryParse(event.startedAt ?? '');
              String formattedDate = startedDateTime != null
                  ? DateFormat('yyyy-MM-dd – kk:mm').format(startedDateTime)
                  : 'Date not available';
              return Container(
                decoration: BoxDecoration(
                  color: getColorFromId(event
                      .colorId), // Set background color based on the event's colorId
                  borderRadius: BorderRadius.circular(5.0),
                ),
                margin: EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(event.taskTitle),
                  subtitle: Text('Started at $formattedDate'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      dataManager.endEvent(event);
                      _showSnackbar("Task finished successfully");
                    },
                    child: Text('Finish'),
                  ),
                ),
              );
            },
          )),
          if (dataManager.activeActivities.isEmpty) ...[
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
