import 'dart:developer' as dev; // Import Dart's developer tools for logging
import 'dart:math';

import 'package:dailyspace/custom_classes/firebase_event.dart';
import 'package:dailyspace/google/firebase_handler.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OptionTwoPage extends StatefulWidget {
  const OptionTwoPage({Key? key}) : super(key: key);

  @override
  _OptionTwoPageState createState() => _OptionTwoPageState();
}

class _OptionTwoPageState extends State<OptionTwoPage> {
  final FirebaseManager firebaseManager = FirebaseManager();
  List<FirebaseEvent> events = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Event Visualization")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Hello"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                var fetchedEvents =
                    await firebaseManager.fetchAndConvertEvents();
                dev.log(fetchedEvents.toString());
                setState(() {
                  events = fetchedEvents;
                  print('Events fetched and stored: $events');
                });
              } catch (e) {
                print('Failed to fetch events: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to fetch events: $e')),
                );
              }
            },
            child: const Text("Fetch Events"),
          ),
          _buildCompletionPercentageBox(),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                FirebaseEvent event = events[index];
                return ListTile(
                  title: Text(event.taskTitle),
                  subtitle:
                      Text('Start: ${event.startTime}, End: ${event.endTime}'),
                  trailing: Text('Duration: ${event.duration}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionPercentageBox() {
    // Calculate the percentage of completed events
    double completedPercentage = _calculateCompletedPercentage();

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Completed: ${completedPercentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateCompletedPercentage() {
    // Count the number of completed events
    int completedCount = events.where((event) => event.endedAt != null).length;

    // Calculate the percentage
    double completedPercentage = (completedCount / events.length) * 100;

    return completedPercentage;
  }
}
