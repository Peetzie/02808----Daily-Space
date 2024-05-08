/*
  Created by: 
  - Zheng Dong
  As part of course 02808 at DTU 2024. 
*/
import 'package:flutter/material.dart';

class RangeSliderDialog {
  static void show(BuildContext context, double initialMax,
      Function(double) onRangeSelected, double currentMax) {
    RangeValues selectedRange = RangeValues(0, currentMax);
    double maxLimit = initialMax;

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
                    max: maxLimit,
                    divisions: maxLimit.toInt(),
                    onChanged: (RangeValues values) {
                      setState(() {
                        selectedRange = RangeValues(
                          values.start.round().toDouble(),
                          values.end.round().toDouble(),
                        );
                      });
                    },
                  ),
                  Text(
                    'Selected Range: ${selectedRange.start.round()} - ${selectedRange.end.round()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
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
