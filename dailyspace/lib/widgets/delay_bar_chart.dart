import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dailyspace/resources/app_colors.dart'; // Ensure this file contains the necessary color definitions.

class DelayBarChart extends StatelessWidget {
  final Map<String, double> averageDelays;
  final int overflowChars = 13;
  DelayBarChart(this.averageDelays);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: findMaxDelay() *
              1.2, // Gives some extra space above the highest bar
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              // Set a background color for tooltips
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  averageDelays.keys.elementAt(groupIndex) + '\n',
                  TextStyle(color: Colors.white),
                  children: <TextSpan>[
                    TextSpan(
                      text: (rod.toY).toStringAsFixed(1) + ' mins',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  String title = averageDelays.keys.elementAt(index);
                  return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 16.0,
                      child: Text(
                        title.length > overflowChars
                            ? title.substring(0, overflowChars) + '...'
                            : title,
                        overflow: title.length > overflowChars
                            ? TextOverflow.ellipsis
                            : TextOverflow.visible,
                      ));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: averageDelays.keys.map((key) {
            final index = averageDelays.keys.toList().indexOf(key);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: averageDelays[key] ?? 0,
                  color: Color.fromARGB(177, 68, 223,
                      40), // Ensure you define this color in AppColors
                  width: 22,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double findMaxDelay() {
    return averageDelays.values.fold(0, (max, e) => e > max ? e : max);
  }
}
