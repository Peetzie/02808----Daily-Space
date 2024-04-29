import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DurationBarChart extends StatelessWidget {
  final Map<String, double> taskDurations;

  const DurationBarChart(this.taskDurations, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String longestTaskName = taskDurations.keys
        .reduce((a, b) => taskDurations[a]! > taskDurations[b]! ? a : b);
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: taskDurations.length * 120.0, // 增加了容器的宽度
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: taskDurations.values.fold(
                            0.0,
                            (prev, element) =>
                                prev > element ? prev : element) +
                        1.0,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final String calendarName =
                              taskDurations.keys.elementAt(group.x.toInt());
                          return BarTooltipItem(
                            '$calendarName: ${rod.toY.round()} hrs',
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
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final String calendarName =
                                taskDurations.keys.elementAt(value.toInt());
                            final String trimmedCalendarName =
                                calendarName.length > 10
                                    ? '${calendarName.substring(0, 10)}...'
                                    : calendarName;
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 16,
                              child: Text(
                                trimmedCalendarName,
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                          reservedSize: 60,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: taskDurations.entries.map((entry) {
                      int index =
                          taskDurations.keys.toList().indexOf(entry.key);
                      final isLongestTask = entry.key == longestTaskName;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            width: 22,
                            fromY: 0,
                            toY: entry.value,
                            color: isLongestTask
                                ? Colors.red
                                : Color.fromARGB(255, 239, 180, 250),
                          ),
                        ],
                      );
                    }).toList(),
                    groupsSpace: 32,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
