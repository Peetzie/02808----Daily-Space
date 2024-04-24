class TaskInfo {
  final String taskId;
  final String title;
  final String? start;
  final String? end;
  final String colorId;

  TaskInfo(this.taskId, this.title, this.start, this.end, this.colorId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskInfo &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId;

  @override
  int get hashCode => taskId.hashCode;
  @override
  String toString() {
    return 'TaskInfo(taskId: $taskId, title: $title, start: $start,end:$end, colorId: $colorId)';
  }

  factory TaskInfo.fromMap(Map<String, dynamic> map) {
    return TaskInfo(
      map['taskId'] as String,
      map['title'] as String,
      map['start'] as String?,
      map['end'] as String?,
      map['colorId'] as String,
    );
  }
}
