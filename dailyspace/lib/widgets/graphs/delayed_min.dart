import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class DelayAverageDurationWidget extends StatelessWidget {
  final Map<Tuple2<String, String>, double> averageDelays;

  const DelayAverageDurationWidget({super.key, required this.averageDelays});

  double computeAverageOfAverages(
      Map<Tuple2<String, String>, double> averages) {
    if (averages.isEmpty) return 0.0;

    double sum = averages.values
        .fold(0.0, (previousSum, element) => previousSum + element);
    return sum / averages.length;
  }

  @override
  Widget build(BuildContext context) {
    final int roundedAverage =
        (computeAverageOfAverages(averageDelays) + 0.5).floor();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 172, 147, 255),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'Task start delayed by an average of   ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '$roundedAverage',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 138, 25, 218),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const TextSpan(
                    text: ' min',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.arrow_downward,
              color: Colors.white, size: 24) // Adding the down arrow icon
        ],
      ),
    );
  }
}
