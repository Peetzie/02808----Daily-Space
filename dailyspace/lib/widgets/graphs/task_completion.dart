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
    String imageAsset;

    if (completionPercentage < 50) {
      imageAsset = 'assets/face1.png'; // Path to your first image
    } else if (completionPercentage < 70) {
      imageAsset = 'assets/face2.png'; // Path to your second image
    } else {
      imageAsset = 'assets/face3.png'; // Path to your third image
    }

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Image.asset(
            imageAsset,
            width: 50, // You can adjust the size here
            height: 50,
          ),
        ],
      ),
    );
  }
}
