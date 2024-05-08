/*
  Created by: 
  - Frederik Peetz-Schou Larsen
  As part of course 02808 at DTU 2024. 
*/
class TaskInfo {
  final String taskId;
  final String calendarName;
  final String title;
  final String? start;
  final String? end;
  final String colorId;

  TaskInfo(this.taskId, this.calendarName, this.title, this.start, this.end,
      this.colorId);

  @override
  String toString() {
    return 'TaskInfo(taskId: $taskId, calendarName: $calendarName,title: $title, start: $start,end:$end, colorId: $colorId)';
  }

  factory TaskInfo.fromMap(Map<String, dynamic> map) {
    return TaskInfo(
      map['taskId'] as String,
      map['calendarName'] as String,
      map['title'] as String,
      map['start'] as String?,
      map['end'] as String?,
      map['colorId'] as String,
    );
  }
}
