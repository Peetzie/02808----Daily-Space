import 'dart:math';

import 'package:dailyspace/datastructures/Timeformatter.dart';
import 'package:dailyspace/sources/app_colors.dart';
import 'package:dailyspace/widgets/graphs/delay_bar_chart.dart';
import 'package:dailyspace/widgets/graphs/delayed_min.dart';
import 'package:dailyspace/widgets/graphs/period_control.dart';
import 'package:dailyspace/widgets/graphs/task_completion.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dailyspace/datastructures/firebase_event.dart';
import 'package:dailyspace/services/firebase_handler.dart';
import 'package:tuple/tuple.dart';

class OptionTwoPage extends StatefulWidget {
  const OptionTwoPage({Key? key}) : super(key: key);

  @override
  _OptionTwoPageState createState() => _OptionTwoPageState();
}

class _OptionTwoPageState extends State<OptionTwoPage> {
  final FirebaseManager firebaseManager = FirebaseManager();
  List<FirebaseEvent> endedEvents = [];
  List<FirebaseEvent> allEvents = [];
  Map<Tuple2<String, String>, double> averageDelays = {};

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      endedEvents.clear();
      allEvents.clear();
      var fetchedEvents = await firebaseManager.fetchAndConvertEndedEvents();
      var allFetchedEvents = await firebaseManager.fetchActiveAndEndedEvents();
      setState(() {
        endedEvents = fetchedEvents;
        allEvents = allFetchedEvents;
        calculateAverageDelays();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch events: $e')),
      );
    }
  }

  void calculateAverageDelays() {
    Map<Tuple2<String, String>, List<int>> delaysByCalendar = {};

    for (var event in endedEvents) {
      if (event.startTime != null && event.startedAt != null) {
        int delay = TimeFormatter.calculateTimeDifferenceInMinutes(
            event.startTime!, event.startedAt!);

        // Use a tuple as the key
        Tuple2<String, String> key = Tuple2(event.calendarName, event.colorId);

        delaysByCalendar.update(key, (delays) {
          delays.add(delay);
          return delays;
        }, ifAbsent: () => [delay]);
      }
    }

    // Calculate average delays
    delaysByCalendar.forEach((calendar, delays) {
      double averageDelay = delays.isNotEmpty
          ? delays.reduce((a, b) => a + b) / delays.length
          : 0;
      averageDelays[calendar] = averageDelay;
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: const Text("Event Visualization")),
      body: Column(
        children: [
          Text(
            "My Report",
            style: TextStyle(
                fontSize: height * 0.03,
                fontWeight: FontWeight.bold,
                color: AppColors.contentColorPurple),
          ),
          SegmentedControl(
            height: height,
          ),

          ElevatedButton(
            onPressed: fetchEvents,
            child: const Text("Refresh Events"),
          ),
          SizedBox(height: 10),
          DelayAverageDurationWidget(averageDelays: averageDelays),
          SizedBox(
            height: 10,
          ),
          TaskCompletionWidget(
              totalTasks: allEvents.length, completedTasks: endedEvents.length),
          SizedBox(height: 20),
          averageDelays.isNotEmpty
              ? DelayBarChart(
                  averageDelays) // Display the DelayBarChart widget with averageDelays data
              : Container(), // Display an empty container if averageDelays is empty
        ],
      ),
    );
  }
}
