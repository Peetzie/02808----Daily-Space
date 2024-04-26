import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DurationBarChart extends StatelessWidget {
  final Map<String, double> taskDurations;

  const DurationBarChart(this.taskDurations, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = max(screenWidth, taskDurations.length * 60.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Text(
              'Task Durations',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8),
            Container(
              height: 200,
              width: chartWidth,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: taskDurations.values.fold(0.0, max) + 1.0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${taskDurations.keys.elementAt(group.x)}: ${rod.toY.toStringAsFixed(2)} hrs',
                          TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 16,
                            child: Text(
                              taskDurations.keys.elementAt(value.toInt()),
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: taskDurations.entries.map((entry) {
                    int index = taskDurations.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          fromY: 0,
                          toY: entry.value,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
