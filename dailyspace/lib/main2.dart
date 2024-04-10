import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Today Tasks',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Today Tasks'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(height: 20),
            // Horizontal ListView for Task Circles
            Container(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  TaskCircle(label: 'Workout', time: '7:30'),
                  TaskCircle(label: 'Breakfast', time: '8:00'),
                  // Add more TaskCircle widgets
                ],
              ),
            ),
            SizedBox(height: 20),
            // Start Task Card
            StartTaskCard(taskName: 'Breakfast', duration: '30 mins'),
            SizedBox(height: 20),
            // Waiting For Finish Section
            WaitingForFinishSection(),
            SizedBox(height: 20),
            // Ended Tasks
            EndedTasksSection(),
          ],
        ),
      ),
    );
  }
}

class TaskCircle extends StatelessWidget {
  final String label;
  final String time;

  TaskCircle({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 30,
            child: Text(time),
          ),
          SizedBox(height: 10),
          Text(label),
        ],
      ),
    );
  }
}

class StartTaskCard extends StatelessWidget {
  final String taskName;
  final String duration;

  StartTaskCard({required this.taskName, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Text('Start task'),
            SizedBox(height: 10),
            Text(taskName),
            SizedBox(height: 10),
            Text(duration),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                ElevatedButton(onPressed: () {}, child: Text('Start Now!')),
                OutlinedButton(onPressed: () {}, child: Text('Later')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WaitingForFinishSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Text('Not yet, keep it up :)'),
    );
  }
}

class EndedTasksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        // Container for Ended Tasks
        );
  }
}
