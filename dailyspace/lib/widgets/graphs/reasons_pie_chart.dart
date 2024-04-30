import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ReasonsPieChart extends StatefulWidget {
  final Map<String, int> reasonCounts;

  const ReasonsPieChart(this.reasonCounts, {Key? key}) : super(key: key);

  @override
  _ReasonsPieChartState createState() => _ReasonsPieChartState();
}

class _ReasonsPieChartState extends State<ReasonsPieChart> {
  List<String> _mostCommonReasons = [];

  @override
  void initState() {
    super.initState();
    _calculateMostCommonReasons();
  }

  void _calculateMostCommonReasons() {
    final maxCount = widget.reasonCounts.values.isNotEmpty
        ? widget.reasonCounts.values.reduce((a, b) => a > b ? a : b)
        : 0;
    _mostCommonReasons = widget.reasonCounts.entries
        .where((entry) => entry.value == maxCount)
        .map((entry) => entry.key)
        .toList();
  }

  List<Color> getGradientColors(int count) {
    List<Color> colors = [];
    Color startColor = Color.fromRGBO(255, 130, 251, 1);
    Color endColor = Color.fromRGBO(152, 48, 250, 1);

    for (int i = 0; i < count; i++) {
      double ratio = i / (count - 1);
      colors.add(Color.lerp(startColor, endColor, ratio)!);
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    var sortedEntries = widget.reasonCounts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    List<Color> gradientColors = getGradientColors(sortedEntries.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reasons Distribution',
                  style: Theme.of(context).textTheme.headline6,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            Container(
              width: 300,
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                  sections: List.generate(sortedEntries.length, (index) {
                    var entry = sortedEntries[index];
                    return PieChartSectionData(
                      color: gradientColors[index],
                      value: entry.value.toDouble(),
                      title: '${entry.key} (${entry.value})',
                      radius: 50.0,
                      titleStyle: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                      titlePositionPercentageOffset: 0.55,
                    );
                  }),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _mostCommonReasons.isNotEmpty
                  ? Text(
                      'The most common reasons for delaying the start of tasks are ${_mostCommonReasons.join(', ')}.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
