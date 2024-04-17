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
}
