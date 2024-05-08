import 'dart:developer' as dev;
import 'package:dailyspace/datastructures/TimePeriod.dart';
import 'package:dailyspace/datastructures/Timeformatter.dart';
import 'package:dailyspace/widgets/graphs/delay_bar_chart.dart';
import 'package:dailyspace/widgets/graphs/delayed_min.dart';
import 'package:dailyspace/widgets/graphs/period_control.dart';
import 'package:dailyspace/widgets/graphs/task_completion.dart';
import 'package:flutter/material.dart';
import 'package:dailyspace/datastructures/firebase_event.dart';
import 'package:dailyspace/services/firebase_handler.dart';
import 'package:tuple/tuple.dart';
import 'package:dailyspace/widgets/graphs/duration_bar_chart.dart';
import 'package:dailyspace/widgets/graphs/reasons_pie_chart.dart';
import 'package:dailyspace/widgets/graphs/longest_task_widget.dart';

class OptionTwoPage extends StatefulWidget {
  const OptionTwoPage({super.key});

  @override
  _OptionTwoPageState createState() => _OptionTwoPageState();
}

extension on DateTime {
  bool isAtLeast(DateTime other) {
    return isAfter(other) || isAtSameMomentAs(other);
  }
}

// Extension method to handle inclusive comparison for start of period
class _OptionTwoPageState extends State<OptionTwoPage> {
  final FirebaseManager firebaseManager = FirebaseManager();
  List<FirebaseEvent> endedEvents = [];
  List<FirebaseEvent> allEvents = [];
  Map<Tuple2<String, String>, double> averageDelays = {};
  Map<String, double> taskDurations = {};
  Map<String, int> reasonCounts = {};
  bool showDelayBarChart = false;
  bool showDurationBarChart = false;

  @override
  void initState() {
    super.initState();
    fetchEvents();
    fetchReasons();
  }

  Future<void> fetchEvents() async {
    try {
      endedEvents.clear();
      allEvents.clear();
      taskDurations.clear();
      var fetchedEvents = await firebaseManager.fetchAndConvertEndedEvents();
      var allFetchedEvents = await firebaseManager.fetchActiveAndEndedEvents();

      setState(() {
        endedEvents = fetchedEvents;
        allEvents = allFetchedEvents;
        calculateAverageDelays();
        calculateTaskDurations();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch events: $e')),
      );
    }
    filterEventsBasedOnSelectedPeriod();
  }

  void calculateTaskDurations() {
    taskDurations.clear();
    for (var event in endedEvents) {
      double durationInMinutes =
          (int.tryParse(event.duration ?? '0') ?? 0).toDouble();
      String calendarName = event.calendarName;
      taskDurations.update(calendarName,
          (existingDuration) => existingDuration + durationInMinutes,
          ifAbsent: () => durationInMinutes);
    }
  }

  MapEntry<String, double>? _taskWithLongestDuration() {
    if (taskDurations.isEmpty) {
      return null;
    }
    return taskDurations.entries
        .reduce((curr, next) => curr.value > next.value ? curr : next);
  }

  void calculateAverageDelays() {
    averageDelays.clear();
    dev.log("all events :${allEvents.length.toString()}");
    dev.log("ended events :${endedEvents.length.toString()}");
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

  void fetchReasons() async {
    try {
      var reasonsList = await firebaseManager.fetchReasons();
      Map<String, int> counts = {};
      for (var reason in reasonsList) {
        counts.update(reason, (value) => value + 1, ifAbsent: () => 1);
      }
      setState(() {
        reasonCounts = counts;
      });
    } catch (e) {
      print('Failed to fetch reasons: $e');
    }
  }

  TimePeriod selectedPeriod = TimePeriod.day;
  void _handleSegmentedControlChange(int newValue) {
    setState(() {
      switch (newValue) {
        case 0:
          selectedPeriod = TimePeriod.day;
          break;
        case 1:
          selectedPeriod = TimePeriod.week;
          break;
        case 2:
          selectedPeriod = TimePeriod.month;
          break;
      }
      fetchEvents(); // Refetch events based on the new period
    });
  }

  void filterEventsBasedOnSelectedPeriod() {
    DateTime now = DateTime.now();
    DateTime startOfPeriod;
    DateTime endOfPeriod;

    switch (selectedPeriod) {
      case TimePeriod.day:
        startOfPeriod = DateTime(now.year, now.month, now.day);
        endOfPeriod =
            startOfPeriod.add(Duration(days: 1)); // Go to the next day
        break;
      case TimePeriod.week:
        int currentWeekday = now.weekday;
        startOfPeriod = now.subtract(Duration(
            days: currentWeekday -
                1)); // Go to the start of the week (assuming Monday is day 1)
        endOfPeriod = startOfPeriod
            .add(Duration(days: 7)); // Add 7 days to cover the week
        break;
      case TimePeriod.month:
        startOfPeriod =
            DateTime(now.year, now.month); // Start of the current month
        endOfPeriod = (now.month < 12)
            ? DateTime(now.year, now.month + 1) // Start of the next month
            : DateTime(now.year + 1, 1); // Start of the next year if December
        break;
    }

    // Ensure the comparison uses only date parts for start of period
    startOfPeriod =
        DateTime(startOfPeriod.year, startOfPeriod.month, startOfPeriod.day);
    endOfPeriod =
        DateTime(endOfPeriod.year, endOfPeriod.month, endOfPeriod.day);

    // Filter the events
    endedEvents = endedEvents.where((event) {
      DateTime? eventStartDate;
      if (event.startedAt != null) {
        try {
          eventStartDate = DateTime.parse(event.startedAt!);
        } catch (e) {
          // Handle the exception if the date format is invalid
          print('Invalid date format: ${event.startedAt}');
        }
      }

      return eventStartDate != null &&
          eventStartDate.isAtLeast(startOfPeriod) &&
          eventStartDate.isBefore(endOfPeriod);
    }).toList();

    // Assuming allEvents also need to be filtered in the same way
    allEvents = allEvents.where((event) {
      DateTime? eventStartDate;
      if (event.startedAt != null) {
        try {
          eventStartDate = DateTime.parse(event.startedAt!);
        } catch (e) {
          // Handle the exception if the date format is invalid
          print('Invalid date format: ${event.startedAt}');
        }
      }

      return eventStartDate != null &&
          eventStartDate.isAtLeast(startOfPeriod) &&
          eventStartDate.isBefore(endOfPeriod);
    }).toList();

    // Recalculate the average delays based on the filtered events
    calculateAverageDelays();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    if (selectedPeriod == TimePeriod.day) {
      dev.log("day");
    } else if (selectedPeriod == TimePeriod.month) {
      dev.log("month");
    } else {
      dev.log("week");
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double baseWidth = screenWidth * 0.9;
    const double uniformSpacing = 30.0;

    var longestTaskEntry = _taskWithLongestDuration();

    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 40),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Text(
              "My Events Report",
              style: TextStyle(
                color: Colors.purple, // Set the color to purple
                fontSize: 24, // Optionally set the font size
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: uniformSpacing),
          SegmentedControl(
            height: height,
            onValueChanged: _handleSegmentedControlChange,
          ),
          SizedBox(height: uniformSpacing),
          Container(
            width: baseWidth,
            child: TaskCompletionWidget(
                totalTasks: allEvents.length,
                completedTasks: endedEvents.length),
          ),
          const SizedBox(height: uniformSpacing),
          GestureDetector(
            onTap: () {
              setState(() {
                showDelayBarChart = !showDelayBarChart;
              });
            },
            child: Container(
              width: baseWidth,
              child: DelayAverageDurationWidget(averageDelays: averageDelays),
            ),
          ),
          const SizedBox(height: 10),
          if (showDelayBarChart)
            Container(
              width: baseWidth,
              child: DelayBarChart(averageDelays),
            ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                showDurationBarChart = !showDurationBarChart;
              });
            },
            child: longestTaskEntry != null
                ? LongestTaskWidget(
                    taskName: longestTaskEntry.key,
                    duration: longestTaskEntry.value,
                  )
                : Container(),
          ),
          if (showDurationBarChart)
            Container(
              width: baseWidth,
              child: DurationBarChart(taskDurations),
            ),
          const SizedBox(height: 20),
          Container(
            width: baseWidth,
            child: reasonCounts.isNotEmpty
                ? ReasonsPieChart(reasonCounts)
                : Text("No data available for reasons."),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ));
  }
}
