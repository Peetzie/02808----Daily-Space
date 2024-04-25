
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

  static String? calculateDuration(DateTime? startedAt, DateTime? endedAt) {
    if (startedAt == null || endedAt == null) return null;
    return endedAt.difference(startedAt).toString();
  }

  static String getCurrentTimestamp() {
    DateTime now = DateTime.now();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  }
}
// Dart Color Definitions for Flutter

