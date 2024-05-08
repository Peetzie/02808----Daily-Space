import 'dart:developer';

import 'package:dailyspace/datastructures/calendar_manager.dart';
import 'package:dailyspace/datastructures/firebase_event.dart';
import 'package:dailyspace/datastructures/taskinfo.dart';
import 'package:dailyspace/screens/acitivity_tracker.dart';
import 'package:dailyspace/services/firebase_handler.dart';
import 'package:dailyspace/services/google_services.dart';
import 'package:dailyspace/services/google_sign_in_manager.dart';
import 'package:dailyspace/widgets/activity_tracker/activity_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart'; // Add this import for BuildContext

class DataManager {
  final BuildContext? context; // Make context nullable

  GoogleSignInAccount? account;
  late Map<String, TaskInfo> availableActivities;
  late Set<FirebaseEvent> activeActivities;
  late Set<TaskInfo> earlyStartActivities;
  Set<String> selectedTaskIds = Set<String>();

  final CalendarManager calendarManager;

  // Constructor with optional context
  DataManager({this.context, required this.calendarManager}) {
    availableActivities = {};
    activeActivities = {};
    earlyStartActivities = {};
  }

  Future<void> fetchAndStoreActivities(GoogleSignInAccount? account) async {
    try {
      log("Runnign fetch and store");
      availableActivities.clear();
      earlyStartActivities.clear();
      // Fetch active tasks from Firebase
      Map<String, FirebaseEvent> firebaseTasks =
          await FirebaseManager().fetchActiveEvents();
      Set<String> endedFirebaseTasksIds =
          await FirebaseManager().fetchAllEndedEventIds();
      Map<String, FirebaseEvent> firebaseDelayedTasks =
          await FirebaseManager().fetchDelayedEvents();
      final tasks = await GoogleServices.fetchTasksFromCalendar(
          account, calendarManager.selectedCalendars);
      log("account" + account.toString());
      log(tasks.toString());
      final now = DateTime.now();

      tasks.values.forEach((task) {
        TaskInfo newTask = TaskInfo(task['taskId'], task['calendarName'],
            task['title'], task['start'], task['end'], task['colorId']);
        if (endedFirebaseTasksIds.contains(newTask.taskId)) {
          return;
        }

        // Check if the task is already active or ended, skip if it is
        if (!firebaseTasks.containsKey(task['taskId']) &&
            !endedFirebaseTasksIds.contains(task['taskId'])) {
          handleTaskTiming(task, now, newTask);
        }
      });

      // Handle delayed tasks
      firebaseDelayedTasks.values.forEach((delayedTask) {
        TaskInfo newTask = TaskInfo(
            delayedTask.taskId,
            delayedTask.calendarName,
            delayedTask.taskTitle,
            delayedTask.delay?.last,
            delayedTask.endTime,
            delayedTask.colorId);
        DateTime taskStart = DateTime.parse(delayedTask.delay!.last);
        int difference = now.difference(taskStart).inMinutes;

        if (DateFormat('yyyy-MM-dd').format(taskStart) ==
            DateFormat('yyyy-MM-dd').format(now)) {
          if (difference.abs() <= 30) {
            earlyStartActivities.add(newTask);
          } else {
            availableActivities[delayedTask.taskId] = newTask;
          }
        } else {
          availableActivities[delayedTask.taskId] = newTask;
        }
      });

      // Convert set to list and sort
      List<TaskInfo> sortedEarlyStartActivities = earlyStartActivities.toList();
      sortedEarlyStartActivities.sort((a, b) {
        DateTime? startTimeA =
            a.start != null ? DateTime.parse(a.start!) : null;
        DateTime? startTimeB =
            b.start != null ? DateTime.parse(b.start!) : null;
        return (startTimeA ?? DateTime(1900))
            .compareTo(startTimeB ?? DateTime(1900));
      });
      earlyStartActivities = sortedEarlyStartActivities.toSet();

      // Sort availableActivities by start time
      List<TaskInfo> sortedAvailableActivities =
          availableActivities.values.toList();
      sortedAvailableActivities.sort((a, b) {
        DateTime? startTimeA =
            a.start != null ? DateTime.parse(a.start!) : null;
        DateTime? startTimeB =
            b.start != null ? DateTime.parse(b.start!) : null;
        return (startTimeA ?? DateTime(1900))
            .compareTo(startTimeB ?? DateTime(1900));
      });
      availableActivities = {
        for (var item in sortedAvailableActivities) item.taskId: item
      };

      earlyStartActivities
          .removeWhere((task) => endedFirebaseTasksIds.contains(task.taskId));
      availableActivities
          .removeWhere((string, key) => endedFirebaseTasksIds.contains(string));
      earlyStartActivities
          .removeWhere((task) => availableActivities.containsKey(task.taskId));
      if (context != null) {
        Provider.of<ActivityManager>(context!, listen: false)
            .setAvailableActivities(availableActivities);
      }
      log("Updated lists of activities based on current statuses.");
    } catch (e) {
      log("Error fetching tasks data manager: ${e.toString()}");
    }
  }

  void handleTaskTiming(
      Map<String, dynamic> task, DateTime now, TaskInfo newTask) {
    DateTime taskStart;
    int difference;
    if (task['start'].contains("T")) {
      // Time-specific task start
      taskStart = DateTime.parse(task['start']);
      difference = taskStart.difference(now).inMinutes;
    } else {
      // Full-day or date-only event
      try {
        taskStart = DateFormat('yyyy-MM-dd').parse(task['start']);
        difference = now.difference(taskStart).inMinutes;
      } catch (e) {
        log("Error parsing date-only start: ${e.toString()}");
        return; // Skip this iteration on parse error
      }

      // Special handling for full-day tasks that start today
      if (DateFormat('yyyy-MM-dd').format(taskStart) ==
          DateFormat('yyyy-MM-dd').format(now)) {
        earlyStartActivities.add(newTask);
        return; // Add to start today and skip further checks
      }
    }

    // Regular checks for tasks with specific times
    if (DateFormat('yyyy-MM-dd').format(taskStart) ==
        DateFormat('yyyy-MM-dd').format(now)) {
      if (difference.abs() <= 30) {
        earlyStartActivities.add(newTask);
      } else {
        availableActivities[task['taskId']] = newTask;
      }
    } else {
      availableActivities[task['taskId']] = newTask;
    }
  }

  Future<void> fetchActiveEvents() async {
    try {
      var activeEventsMap = await firebaseManager.fetchActiveEvents();
      activeActivities = activeEventsMap.values.toSet();
    } catch (e) {
      debugPrint('Error fetching active events: ${e.toString()}');
    }
  }

  void endEvent(FirebaseEvent event) async {
    try {
      await firebaseManager.endEvent(event.taskId.toString());
      fetchActiveEvents();
    } catch (e) {
      debugPrint('Error ending event: ${e.toString()}');
    }
  }
}
