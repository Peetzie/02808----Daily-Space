import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DurationBarChart extends StatelessWidget {
  final Map<String, double> taskDurations;

  const DurationBarChart(this.taskDurations, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 200,
        width: max(taskDurations.length * 60.0, 300),
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
                      space: 16, // Adjust space if necessary
                      child: Text(
                        taskDurations.keys.elementAt(value.toInt()),
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles:
                      false, // Typically you might want to set this to true and configure accordingly
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
    );
  }
}
