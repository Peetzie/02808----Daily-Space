import 'package:dailyspace/custom_classes/taskinfo.dart';
import 'package:intl/intl.dart'; // Include to format DateTime

class FirebaseEvent {
  final String taskId;
  final String taskTitle;
  final String? startTime;
  final String? endTime;
  final String colorId;
  final String? startedAt; // Changed to String? to store formatted DateTime
  final String? endedAt; // Changed to String? to store formatted DateTime
  final String? duration;

  FirebaseEvent(this.taskId, this.taskTitle, this.startTime, this.endTime,
      this.colorId, this.startedAt, this.endedAt, this.duration);

  @override
  String toString() {
    return 'FirebaseEvent(taskId: $taskId, title: $taskTitle, start: $startTime, end: $endTime, colorId: $colorId)';
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'taskTitle': taskTitle,
      'startTime': startTime,
      'endTime': endTime,
      'colorId': colorId,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'duration': duration,
    };
  }

  static FirebaseEvent fromMap(Map<String, dynamic> map) {
    return FirebaseEvent(
      map['taskId'] as String,
      map['taskTitle'] as String,
      map['startTime'] as String?,
      map['endTime'] as String?,
      map['colorId'] as String,
      map['startedAt'] as String?,
      map['endedAt'] as String?,
      map['duration'] as String?,
    );
  }

  static FirebaseEvent fromTaskInfo(
      TaskInfo task, DateTime? startedAt, DateTime? endedAt, String? duration) {
    String? formatDateTime(DateTime? datetime) {
      return datetime != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(datetime)
          : null;
    }

    return FirebaseEvent(
        task.taskId,
        task.title,
        task.start, // Ensure these are correctly formatted or null
        task.end, // Ensure these are correctly formatted or null
        task.colorId,
        formatDateTime(startedAt),
        formatDateTime(endedAt),
        duration);
  }
}
