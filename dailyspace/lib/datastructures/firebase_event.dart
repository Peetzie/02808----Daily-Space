/*
  Created by: 
  - Frederik Peetz-Schou Larsen
  As part of course 02808 at DTU 2024. 
*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailyspace/datastructures/taskinfo.dart';

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
  final List<String>? reasons;
  final List<String>? delay;

  FirebaseEvent(
      this.taskId,
      this.calendarName,
      this.taskTitle,
      this.startTime,
      this.endTime,
      this.colorId,
      this.startedAt,
      this.endedAt,
      this.duration,
      this.reasons,
      this.delay);

  @override
  String toString() {
    return 'FirebaseEvent(taskId: $taskId, calendarName: $calendarName, taskTitle: $taskTitle, startTime: $startTime, endTime: $endTime, colorId: $colorId, startedAt: $startedAt, endedAt: $endedAt, duration: $duration, reasons: $reasons, reasons: $delay)';
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
      'reasons': reasons,
      'delay': delay,
    };
  }

  static FirebaseEvent fromTaskInfo(
      TaskInfo task,
      String? startedAt,
      String? endedAt,
      String? duration,
      List<String>? reasons,
      List<String>? delay) {
    return FirebaseEvent(
        task.taskId,
        task.calendarName,
        task.title,
        task.start, // Ensure these are correctly formatted or null
        task.end, // Ensure these are correctly formatted or null
        task.colorId,
        startedAt,
        endedAt,
        duration,
        reasons,
        delay);
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
      (map['reasons'] as List<dynamic>?)?.cast<String>(),
      (map['delay'] as List<dynamic>?)
          ?.map<String>((item) =>
              item is Timestamp ? item.toDate().toString() : item as String)
          .toList(),
    );
  }
}
