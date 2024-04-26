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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Reasons Distribution',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            Container(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                  sections: widget.reasonCounts.entries.map((entry) {
                    return PieChartSectionData(
                      color: Colors.primaries[
                          widget.reasonCounts.keys.toList().indexOf(entry.key) %
                              Colors.primaries.length],
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
                  }).toList(),
                ),
              ),
            ),
            // Add the information text below the PieChart for multiple common reasons
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
