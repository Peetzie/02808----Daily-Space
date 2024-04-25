import 'package:dailyspace/sources/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class DelayAverageDurationWidget extends StatelessWidget {
  final Map<Tuple2<String, String>, double> averageDelays;

  const DelayAverageDurationWidget({Key? key, required this.averageDelays})
      : super(key: key);
  double computeAverageOfAverages(
      Map<Tuple2<String, String>, double> averages) {
    if (averages.isEmpty) return 0.0;

    double sum = averages.values
        .fold(0.0, (previousSum, element) => previousSum + element);
    return sum / averages.length;
  }

  @override
  Widget build(BuildContext context) {
    final double average = computeAverageOfAverages(averageDelays);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.contentColorPurple.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ]),
      child: Text("Task start delayed by an average of ${average} min"),
    );
  }
}
