import 'dart:developer';

import 'package:dailyspace/custom_classes/helper.dart';
import 'package:dailyspace/resources/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class DelayBarChart extends StatelessWidget {
  final Map<Tuple2<String, String>, double> averageDelays;
  final int overflowChars = 8;
  double yMax = 100;

  DelayBarChart(this.averageDelays);

  @override
  Widget build(BuildContext context) {
    double combinedAverageDelay = computeAverageOfAverages(averageDelays);
    double height = MediaQuery.of(context).size.height * 0.25;
    double width = MediaQuery.of(context).size.width * 0.8;
    return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.contentColorPurple.withAlpha(30),
          borderRadius: BorderRadius.circular(width * 0.03),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 3,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(10),
        child: Container(
          alignment: Alignment.center,
          height: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: BarChart(
            swapAnimationDuration: Duration(milliseconds: 70), // Optional
            swapAnimationCurve: Curves.linear,
            BarChartData(
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                    y: combinedAverageDelay,
                    label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (line) =>
                            'Avg: ${line.y.toStringAsFixed(1)} mins', // Customize label text
                        style: TextStyle(
                          color: AppColors.contentColorRed.withAlpha(90),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        )),
                    color: AppColors.contentColorRed.withAlpha(90),
                    strokeWidth: 2,
                    dashArray: [5, 5])
              ]),
              alignment: BarChartAlignment.spaceAround,
              maxY: yMax,
              minY: -30,
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
                          text: '${averageDelays[key]} mins',
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
              gridData: FlGridData(
                  show: true,
                  checkToShowHorizontalLine: (value) => value % yMax == 0,
                  getDrawingHorizontalLine: (value) {
                    // Returning default line for other values
                    return FlLine(
                        color: Color.fromARGB(255, 46, 48, 52), strokeWidth: 1);
                  }),
              borderData: FlBorderData(show: false),
              barGroups: averageDelays.keys.map((key) {
                final index = averageDelays.keys.toList().indexOf(key);
                final keysplit = averageDelays.keys.elementAt(index);
                final colorId = keysplit.item2;
                double yval = averageDelays[key] ?? 0;
                bool isOverflowing = yval > yMax;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: isOverflowing ? yMax : yval,
                      color: getColorFromId(
                          colorId), // Use colorMap to get color dynamically
                      width: 4,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ));
  }

  double findMaxDelay() {
    return averageDelays.values.fold(0, (max, e) => e > max ? e : max);
  }

  double computeAverageOfAverages(
      Map<Tuple2<String, String>, double> averages) {
    if (averages.isEmpty) return 0.0;

    double sum = averages.values
        .fold(0.0, (previousSum, element) => previousSum + element);
    return sum / averages.length;
  }
}
