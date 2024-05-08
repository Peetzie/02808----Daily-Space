/*
  Created by: 
  - Frederik Peetz-Schou Larsen
  As part of course 02808 at DTU 2024. 
*/
import 'package:intl/intl.dart';

class TimeFormatter {
  static String formatTime(String? datetimeStr) {
    if (datetimeStr != null && datetimeStr.isNotEmpty) {
      // Check if the input is in the format "yyyy-MM-dd"
      RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (dateRegex.hasMatch(datetimeStr)) {
        return "";
      } else {
        DateTime dateTime = DateTime.parse(datetimeStr).toLocal();
        // Use DateFormat from the intl package to format the time part in 24-hour format
        String formattedTime = DateFormat('HH:mm').format(dateTime);
        return formattedTime;
      }
    }
    return "";
  }

  String calculateDuration(String? start, String? end) {
    if (start == null || end == null) {
      return 'Duration Unknown';
    }
    DateTime startTime = DateTime.parse(start);
    DateTime endTime = DateTime.parse(end);
    Duration duration = endTime.difference(startTime);
    return "${duration.inHours}h ${duration.inMinutes % 60}m";
  }

  static String convertDurationToISO8601(Duration duration) {
    // Get the current date and time
    DateTime now = DateTime.now();

    // Add the duration to the current date and time
    DateTime delayedDateTime = now.add(duration);

    // Format the delayed date and time to ISO 8601 format
    String iso8601DateTime = delayedDateTime.toIso8601String();

    return iso8601DateTime;
  }

  static int calculateTimeDifferenceInMinutes(
      String? timestamp1, String? timestamp2) {
    if (timestamp1 == null || timestamp2 == null) {
      return 0; // or handle null case as needed
    }

    // Parse timestamps
    DateTime dateTime1 = DateTime.parse(timestamp1);
    DateTime dateTime2 = DateTime.parse(timestamp2);

    // Calculate difference
    Duration difference = dateTime2.difference(dateTime1);
    int differenceInMinutes = difference.inMinutes;
    return differenceInMinutes;
  }

  static String getFormattedDate() {
    DateTime now = DateTime.now();
    DateFormat dateFormat = DateFormat('EEEE, dd/MM HH:mm:ss');
    return dateFormat.format(now);
  }

  static String calculateDurationString(String? start, String? end) {
    if (start == null || end == null) {
      return 'Duration Unknown';
    }
    DateTime startTime = DateTime.parse(start);
    DateTime endTime = DateTime.parse(end);
    Duration duration = endTime.difference(startTime);
    return "${duration.inHours}h ${duration.inMinutes % 60}m";
  }

  static String getCurrentTimestamp() {
    DateTime now = DateTime.now();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  }
}
// Dart Color Definitions for Flutter

