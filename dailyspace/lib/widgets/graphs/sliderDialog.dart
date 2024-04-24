import 'package:flutter/material.dart';

class RangeSliderDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double initialValue = 50; // initial value for range slider
        RangeValues selectedRange = RangeValues(0, 100); // range for slider
        return AlertDialog(
          title: Text('Select Range'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RangeSlider(
                    values: selectedRange,
                    min: 0,
                    max: 100,
                    onChanged: (RangeValues values) {
                      setState(() {
                        selectedRange = values;
                      });
                    },
                  ),
                  Text(
                    'Selected Range: ${selectedRange.start} - ${selectedRange.end}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Apply'),
              onPressed: () {
                // Apply the selected range
                // You can pass the selected range values to wherever needed
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
