import 'package:flutter/material.dart';

class RangeSliderDialog {
  static void show(BuildContext context, double initialMax,
      Function(double) onRangeSelected) {
    RangeValues selectedRange = RangeValues(0, initialMax);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Range'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RangeSlider(
                    values: selectedRange,
                    min: 0,
                    max: initialMax,
                    onChanged: (RangeValues values) {
                      setState(() {
                        selectedRange = values;
                      });
                    },
                  ),
                  Text(
                    'Selected Range: ${selectedRange.start} - ${selectedRange.end}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Apply'),
              onPressed: () {
                onRangeSelected(selectedRange.end);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
