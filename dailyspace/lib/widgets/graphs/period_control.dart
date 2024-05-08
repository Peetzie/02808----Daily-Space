/*
  Created by: 
  - Frederik Peetz-Schou Larsen
  As part of course 02808 at DTU 2024. 
*/
import 'package:dailyspace/sources/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef SelectionChanged<T> = void Function(T selection);

class SegmentedControl extends StatefulWidget {
  final double height;
  final SelectionChanged<int> onValueChanged;
  const SegmentedControl(
      {super.key, required this.height, required this.onValueChanged});

  @override
  _SegmentedControlState createState() => _SegmentedControlState();
}

class _SegmentedControlState extends State<SegmentedControl> {
  int sharedValue = 0;

  @override
  Widget build(BuildContext context) {
    // Calculate font size based on the height of the widget
    final double fontSize = widget.height * 0.017;
    // Control the padding to affect the roundness

    final Map<int, Widget> tabs = {
      0: Text(
        'Day',
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
        ),
      ),
      1: Text(
        'Week',
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
        ),
      ),
      2: Text(
        'Month',
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
        ),
      ),
    };

    return Container(
      width: double
          .infinity, // This will make the segmented control take up full width
      padding: const EdgeInsets.symmetric(
          horizontal:
              30), // Add padding if you want some space from the screen edges
      child: CupertinoSegmentedControl<int>(
        children: tabs,
        onValueChanged: (int newValue) {
          setState(() {
            sharedValue = newValue;
          });
          widget.onValueChanged(newValue);
        },
        groupValue: sharedValue,
        borderColor: Colors.black,
        selectedColor: AppColors.contentColorPurple.withAlpha(30),
        unselectedColor: Colors.white,
        pressedColor: Colors.blue.withOpacity(0.3),
        padding: const EdgeInsets.all(10),
        // Increase the border radius for a more rounded look
      ),
    );
  }
}
