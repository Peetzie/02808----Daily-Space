import 'dart:developer'; // Import Dart's developer tools for logging
import 'dart:math';

import 'package:dailyspace/custom_classes/firebase_event.dart';
import 'package:dailyspace/google/firebase_handler.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OptionTwoPage extends StatefulWidget {
  const OptionTwoPage({super.key});

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
}
