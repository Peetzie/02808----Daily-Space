import 'package:flutter/material.dart';
import 'package:dailyspace/custom_classes/taskinfo.dart';

class ActivityManager with ChangeNotifier {
  Map<String, TaskInfo>? _availableActivities;

  Map<String, TaskInfo>? get availableActivities => _availableActivities;

  void setAvailableActivities(Map<String, TaskInfo>? activities) {
    _availableActivities = activities;
    notifyListeners();
  }
}
