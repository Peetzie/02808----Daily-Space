/*
  Created by: 
  - Frederik Peetz-Schou Larsen
  As part of course 02808 at DTU 2024. 
*/
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class OpenDelayDialog extends StatefulWidget {
  @override
  _OpenDelayDialogState createState() => _OpenDelayDialogState();
}

class _OpenDelayDialogState extends State<OpenDelayDialog> {
  int _days = 0;
  int _hours = 0;
  int _minutes = 15;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Delay'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Column for Days
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Days'),
              NumberPicker(
                value: _days,
                minValue: 0,
                maxValue: 365,
                onChanged: (value) => setState(() => _days = value),
              ),
            ],
          ),
          // Column for Hours
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Hours'),
              NumberPicker(
                value: _hours,
                minValue: 0,
                maxValue: 23,
                onChanged: (value) => setState(() => _hours = value),
              ),
            ],
          ),
          // Column for Minutes
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Minutes'),
              NumberPicker(
                value: _minutes,
                minValue: 0,
                maxValue: 59,
                onChanged: (value) => setState(() => _minutes = value),
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            // Return null when cancel button is pressed
            Navigator.of(context).pop(null);
          },
        ),
        TextButton(
          child: const Text('Set Delay'),
          onPressed: () {
            // Return the selected delay when set delay button is pressed
            Duration delayDuration =
                Duration(days: _days, hours: _hours, minutes: _minutes);
            Navigator.of(context).pop(delayDuration);
          },
        ),
      ],
    );
  }
}
