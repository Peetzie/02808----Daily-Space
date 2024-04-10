class TaskInfo {
  final String taskId;
  final String title;
  final String? due;

  TaskInfo(this.taskId, this.title, this.due);

  @override
  String toString() {
    return 'TaskInfo(taskId: $taskId, title: $title, due: $due)';
  }
}
