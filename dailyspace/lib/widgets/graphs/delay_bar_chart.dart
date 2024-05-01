import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dailyspace/sources/app_colors.dart';
import 'package:dailyspace/widgets/graphs/sliderDialog.dart';

class DelayBarChart extends StatefulWidget {
  final Map<Tuple2<String, String>, double> averageDelays;

  DelayBarChart(this.averageDelays, {super.key});

  @override
  _DelayBarChartState createState() => _DelayBarChartState();
}

class _DelayBarChartState extends State<DelayBarChart> {
  late double yMax;

  @override
  void initState() {
    super.initState();
    yMax = widget.averageDelays.values
        .fold(0, (prev, element) => element > prev ? element : prev);
  }

  void updateYMax(double newMax) {
    setState(() {
      yMax = newMax;
    });
  }

  @override
  Widget build(BuildContext context) {
    double combinedAverageDelay =
        computeAverageOfAverages(widget.averageDelays);
    String maxDurationCategory = findMaxDurationCategory();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(10.0),
          child: Text('Delay Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Stack(
          children: [
            Container(
              alignment: Alignment.center,
              height: 300,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.contentColorPurple.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: BarChart(
                swapAnimationDuration:
                    const Duration(milliseconds: 70), // Optional
                swapAnimationCurve: Curves.linear,
                BarChartData(
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: combinedAverageDelay,
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (line) =>
                            'Avg: ${line.y.toStringAsFixed(1)} mins',
                        style: TextStyle(
                          color: AppColors.contentColorRed.withAlpha(90),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      color: AppColors.contentColorRed.withAlpha(90),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    )
                  ]),
                  alignment: BarChartAlignment.spaceAround,
                  maxY: yMax,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final key =
                            widget.averageDelays.keys.elementAt(groupIndex);
                        return BarTooltipItem(
                          '${key.item1}\n',
                          const TextStyle(color: Colors.white),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${widget.averageDelays[key]} mins',
                              style: const TextStyle(
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
                          final key =
                              widget.averageDelays.keys.elementAt(index);
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 16.0,
                            child: Text(
                              key.item1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: widget.averageDelays.keys.map((key) {
                    final yval = widget.averageDelays[key] ?? 0;
                    return BarChartGroupData(
                      x: widget.averageDelays.keys.toList().indexOf(key),
                      barRods: [
                        BarChartRodData(
                          toY: yval > yMax ? yMax : yval,
                          color: Colors.blue,
                          width: 4,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  RangeSliderDialog.show(context, yMax, updateYMax);
                },
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text('You spent the longest time on: $maxDurationCategory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  String findMaxDurationCategory() {
    double maxDuration = 0.0;
    String maxCategory = '';
    widget.averageDelays.forEach((key, value) {
      if (value > maxDuration) {
        maxDuration = value;
        maxCategory = key.item1;
      }
    });
    return maxCategory;
  }

  double computeAverageOfAverages(
      Map<Tuple2<String, String>, double> averages) {
    if (averages.isEmpty) return 0.0;
    double sum = averages.values
        .fold(0.0, (previousSum, element) => previousSum + element);
    return sum / averages.length;
  }
}
