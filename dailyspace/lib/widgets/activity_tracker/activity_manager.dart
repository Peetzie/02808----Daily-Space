/*
  Created by: 
  - Zheng Dong
  As part of course 02808 at DTU 2024. 
*/
import 'package:flutter/material.dart';
import 'package:dailyspace/datastructures/taskinfo.dart';

class ActivityManager with ChangeNotifier {
  Map<String, TaskInfo>? _availableActivities;

  Map<String, TaskInfo>? get availableActivities => _availableActivities;

  void setAvailableActivities(Map<String, TaskInfo>? activities) {
    _availableActivities = activities;
    notifyListeners();
  }
}
