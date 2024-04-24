import 'dart:math';

import 'package:dailyspace/custom_classes/helper.dart';
import 'package:dailyspace/resources/app_colors.dart';
import 'package:dailyspace/widgets/delay_bar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dailyspace/custom_classes/firebase_event.dart';
import 'package:dailyspace/google/firebase_handler.dart';

class OptionTwoPage extends StatefulWidget {
  const OptionTwoPage({Key? key}) : super(key: key);

  @override
  _OptionTwoPageState createState() => _OptionTwoPageState();
}

class _OptionTwoPageState extends State<OptionTwoPage> {
  final FirebaseManager firebaseManager = FirebaseManager();
  List<FirebaseEvent> events = [];
  Map<String, double> averageDelays = {};

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      var fetchedEvents = await firebaseManager.fetchAndConvertEvents();
      setState(() {
        events = fetchedEvents;
        calculateAverageDelays();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch events: $e')),
      );
    }
  }

  void calculateAverageDelays() {
    Map<String, List<int>> delaysByCalendar = {};

    for (var event in events) {
      if (event.startTime != null && event.startedAt != null) {
        int delay = TimeFormatter.calculateTimeDifferenceInMinutes(
            event.startTime!, event.startedAt!);
        delaysByCalendar.update(event.calendarName, (delays) {
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
    return Scaffold(
      appBar: AppBar(title: const Text("Event Visualization")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: fetchEvents,
            child: const Text("Refresh Events"),
          ),
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
