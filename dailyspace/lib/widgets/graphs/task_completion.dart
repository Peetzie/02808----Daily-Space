import 'package:flutter/material.dart';

class TaskCompletionWidget extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;

  const TaskCompletionWidget({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
  });

  @override
  Widget build(BuildContext context) {
    final double completionPercentage =
        totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 161, 157, 255),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          text: 'Task Completion Rate:   ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          children: <TextSpan>[
            TextSpan(
              text: '${completionPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Color.fromARGB(255, 162, 23, 255),
                fontWeight: FontWeight.bold,
                fontSize: 24, // Increase this value to adjust the font size
              ),
            ),
          ],
        ),
      ),
    );
  }
}
