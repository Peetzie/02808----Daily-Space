class TaskInfo {
  final String taskId;
  final String title;
  final String? due;
  final String colorId;

  TaskInfo(this.taskId, this.title, this.due, this.colorId);

  @override
  String toString() {
    return 'TaskInfo(taskId: $taskId, title: $title, due: $due, colorId: $colorId)';
  }
}
