import 'package:flutter/material.dart';

class LongestTaskWidget extends StatelessWidget {
  final String taskName;
  final double duration;

  const LongestTaskWidget({
    Key? key,
    required this.taskName,
    required this.duration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 60,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 186, 147, 199),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "Task with the longest duration",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            "${duration.toStringAsFixed(2)} hrs",
            style: TextStyle(
              color: Color.fromARGB(255, 138, 25, 218),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
