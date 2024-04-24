import 'dart:math';

import 'package:dailyspace/screens/vis.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Import your login screen widget
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KindaCode.com',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: HomePage(),
    );
  }
}

// Define data structure for a bar group
class DataItem {
  int x;
  double y1;
  double y2;
  double y3;
  DataItem(
      {required this.x, required this.y1, required this.y2, required this.y3});
}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);
  // Generate dummy data to feed the chart
  final List<DataItem> _myData = List.generate(
      30,
      (index) => DataItem(
            x: index,
            y1: Random().nextInt(20) + Random().nextDouble(),
            y2: Random().nextInt(20) + Random().nextDouble(),
            y3: Random().nextInt(20) + Random().nextDouble(),
          ));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Piechart'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(30),
          child: PieChart(PieChartData(
              centerSpaceRadius: 5,
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              sections: [
                PieChartSectionData(
                    value: 35, color: Colors.purple, radius: 100),
                PieChartSectionData(
                    value: 40, color: Colors.amber, radius: 100),
                PieChartSectionData(
                    value: 55, color: Colors.green, radius: 100),
                PieChartSectionData(
                    value: 70, color: Colors.orange, radius: 100),
              ]))),
    );
  }
}
