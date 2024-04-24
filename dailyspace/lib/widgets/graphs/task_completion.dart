import 'package:flutter/material.dart';

class TaskCompletionWidget extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;

  const TaskCompletionWidget({
    Key? key,
    required this.totalTasks,
    required this.completedTasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double completionPercentage =
        totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Completion: ${completionPercentage.toStringAsFixed(1)}%',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
