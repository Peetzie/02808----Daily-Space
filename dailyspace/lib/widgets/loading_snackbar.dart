/*
  Created by: 
  - Frederik Peetz-Schou Larsen
  As part of course 02808 at DTU 2024. 
*/
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

void showLoadingSnackbar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Row(
          children: [
            LoadingAnimationWidget.discreteCircle(
              color: Colors.white,
              secondRingColor: Colors.purple,
              thirdRingColor: Colors.blue,
              size: 30,
            ), // Display a loading indicator
            SizedBox(width: 20), // Add some space
            Text("Fetching data from GCloud"), // Display loading text
          ],
        ),
        duration: Duration(days: 10)),
  );
}
