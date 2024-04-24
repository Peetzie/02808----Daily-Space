import 'dart:developer';

import 'package:dailyspace/custom_classes/helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class DelayBarChart extends StatelessWidget {
  final Map<Tuple2<String, String>, double> averageDelays;
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
                final key = averageDelays.keys.elementAt(groupIndex);
                final calendarName = key.item1;
                final colorId = key.item2;
                return BarTooltipItem(
                  calendarName + '\n',
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
                  final key = averageDelays.keys.elementAt(index);
                  final calendarName = key.item1;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 16.0,
                    child: Text(
                      calendarName.length > overflowChars
                          ? calendarName.substring(0, overflowChars) + '...'
                          : calendarName,
                      overflow: calendarName.length > overflowChars
                          ? TextOverflow.ellipsis
                          : TextOverflow.visible,
                    ),
                  );
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
            final keysplit = averageDelays.keys.elementAt(index);
            final colorId = keysplit.item2;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: averageDelays[key] ?? 0,
                  color: getColorFromId(
                      colorId), // Use colorMap to get color dynamically
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
