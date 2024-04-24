import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailyspace/custom_classes/taskinfo.dart';
import 'package:intl/intl.dart';

class FirebaseEvent {
  final String taskId;
  final String calendarName;
  final String taskTitle;
  final String? startTime;
  final String? endTime;
  final String colorId;
  final String? startedAt;
  final String? endedAt;
  final String? duration;

  FirebaseEvent(this.taskId, this.calendarName, this.taskTitle, this.startTime,
      this.endTime, this.colorId, this.startedAt, this.endedAt, this.duration);

  @override
  String toString() {
    return 'FirebaseEvent(taskId: $taskId, calendarName: $calendarName, taskTitle: $taskTitle, startTime: $startTime, endTime: $endTime, colorId: $colorId, startedAt: $startedAt, endedAt: $endedAt, duration: $duration)';
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'calendarName': calendarName,
      'taskTitle': taskTitle,
      'startTime': startTime,
      'endTime': endTime,
      'colorId': colorId,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'duration': duration,
    };
  }

  static FirebaseEvent fromTaskInfo(
      TaskInfo task, DateTime? startedAt, DateTime? endedAt, String? duration) {
    String? formatDateTime(DateTime? datetime) {
      return datetime != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(datetime).toString()
          : null;
    }

    return FirebaseEvent(
        task.taskId,
        task.calendarName,
        task.title,
        task.start, // Ensure these are correctly formatted or null
        task.end, // Ensure these are correctly formatted or null
        task.colorId,
        formatDateTime(startedAt),
        formatDateTime(endedAt),
        duration);
  }

  static FirebaseEvent fromMap(Map<String, dynamic> map) {
    return FirebaseEvent(
      map['taskId'] as String,
      map['calendarName'] as String,
      map['taskTitle'] as String,
      map['startTime'] is Timestamp
          ? (map['startTime'] as Timestamp).toDate().toString()
          : map['startTime'] as String?,
      map['endTime'] is Timestamp
          ? (map['endTime'] as Timestamp).toDate().toString()
          : map['endTime'] as String?,
      map['colorId'] as String,
      map['startedAt'] is Timestamp
          ? (map['startedAt'] as Timestamp).toDate().toString()
          : map['startedAt'] as String?,
      map['endedAt'] is Timestamp
          ? (map['endedAt'] as Timestamp).toDate().toString()
          : map['endedAt'] as String?,
      map['duration'] as String?,
    );
  }
}
