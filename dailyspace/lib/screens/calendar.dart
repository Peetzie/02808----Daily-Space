import 'package:flutter/material.dart';
import 'package:dailyspace/custom_classes/taskinfo.dart';
import 'package:intl/intl.dart';

class Calendar extends StatelessWidget {
  final Map<String, TaskInfo>? availableActivities;

  const Calendar({Key? key, this.availableActivities}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, TaskInfo> activities =
        ModalRoute.of(context)?.settings.arguments as Map<String, TaskInfo>? ??
            availableActivities ??
            {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar Activities'),
        backgroundColor: Colors.blue,
      ),
      body: activities.isEmpty
          ? Center(
              child: Text('No activities available'),
            )
          : buildActivitiesList(activities),
    );
  }

  Widget buildActivitiesList(Map<String, TaskInfo> activities) {
    return ListView.builder(
      itemCount: activities.length,
      itemBuilder: (context, index) {
        TaskInfo task = activities.values.elementAt(index);
        return Card(
          child: ListTile(
            title: Text(task.title),
            subtitle: Text(
                'Start: ${formatDateTime(task.start)} - End: ${formatDateTime(task.end)}\nDuration: ${calculateDuration(task.start, task.end)}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) {
      return 'Unknown time';
    }
    DateTime dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime); // 格式化时间
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
}
