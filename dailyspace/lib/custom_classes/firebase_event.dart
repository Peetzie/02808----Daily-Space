import 'package:dailyspace/custom_classes/taskinfo.dart';

class FirebaseEvent {
  final String taskId;
  final String taskTitle;
  final String? startTime;
  final String? endTime;
  final String colorId;
  final String? startedAt;
  final String? endedAt;
  final String? duration;

  FirebaseEvent(this.taskId, this.taskTitle, this.startTime, this.endTime,
      this.colorId, this.startedAt, this.endedAt, this.duration);

  @override
  String toString() {
    return 'FirebaseEvent(taskId: $taskId, title: $taskTitle, start: $startTime,end:$endTime, colorId: $colorId)';
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

  static FirebaseEvent fromTaskInfo(TaskInfo task) {
    return FirebaseEvent(
        task.taskId,
        task.title,
        task.start,
        task.end,
        task.colorId,
        null, // Or set as needed
        null, // Or set as needed
        null // Or calculate as needed
        );
  }
}
