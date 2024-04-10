import 'dart:developer';

import 'package:intl/intl.dart';

class TimeFormatter {
  static String formatTime(String? datetimeStr) {
    DateTime dateTime = DateTime.parse(datetimeStr.toString());
    // Use DateFormat from the intl package to format the time part in 24-hour format
    String formattedTime = DateFormat('HH:mm').format(dateTime);
    return formattedTime;
  }
}
