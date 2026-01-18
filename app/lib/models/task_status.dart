class TaskStatus {
  final String taskId;
  final String
  status; // "pending", "running", "completed", "failed", "cancelled"
  final double progress;
  final String? result;
  final String? error;

  TaskStatus({
    required this.taskId,
    required this.status,
    required this.progress,
    this.result,
    this.error,
  });

  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    return TaskStatus(
      taskId: json['task_id'],
      status: json['status'],
      progress: (json['progress'] as num).toDouble(),
      result: json['result'],
      error: json['error'],
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';
  bool get isRunning => status == 'running' || status == 'pending';
}
