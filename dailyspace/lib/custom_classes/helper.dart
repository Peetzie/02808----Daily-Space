import 'dart:developer';

import 'package:flutter/material.dart';
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
String getCurrentTimestamp() {
  DateTime now = DateTime.now();
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
}

class Palette {
  static const Color lavender = Color(0xFFac725e);
  static const Color sage = Color(0xFFd06b64);
  static const Color grape = Color(0xFFf83a22);
  static const Color flamingo = Color(0xFFfa573c);
  static const Color banana = Color(0xFFff7537);
  static const Color tangerine = Color(0xFFffad46);
  static const Color peacock = Color(0xFF42d692);
  static const Color graphite = Color(0xFF16a765);
  static const Color blueberry = Color(0xFF7bd148);
  static const Color basil = Color(0xFFb3dc6c);
  static const Color tomato = Color(0xFFfbe983);
  static const Color lightOrange = Color(0xFFfad165);
  static const Color lightGreen = Color(0xFF92e1c0);
  static const Color lightBlue = Color(0xFF9fe1e7);
  static const Color skyBlue = Color(0xFF9fc6e7);
  static const Color royalBlue = Color(0xFF4986e7);
  static const Color blueViolet = Color(0xFF9a9cff);
  static const Color violet = Color(0xFFb99aff);
  static const Color silver = Color(0xFFc2c2c2);
  static const Color dustyRose = Color(0xFFcabdbf);
  static const Color mauve = Color(0xFFcca6ac);
  static const Color lightPink = Color(0xFFf691b2);
  static const Color orchid = Color(0xFFcd74e6);
  static const Color mediumPurple = Color(0xFFa47ae2);
}

Color getColorFromId(String colorId) {
  switch (colorId) {
    case "1":
      return Palette.lavender;
    case "2":
      return Palette.sage;
    case "3":
      return Palette.grape;
    case "4":
      return Palette.flamingo;
    case "5":
      return Palette.banana;
    case "6":
      return Palette.tangerine;
    case "7":
      return Palette.peacock;
    case "8":
      return Palette.graphite;
    case "9":
      return Palette.blueberry;
    case "10":
      return Palette.basil;
    case "11":
      return Palette.tomato;
    case "12":
      return Palette.lightOrange;
    case "13":
      return Palette.lightGreen;
    case "14":
      return Palette.lightBlue;
    case "15":
      return Palette.skyBlue;
    case "16":
      return Palette.royalBlue;
    case "17":
      return Palette.blueViolet;
    case "18":
      return Palette.violet;
    case "19":
      return Palette.silver;
    case "20":
      return Palette.dustyRose;
    case "21":
      return Palette.mauve;
    case "22":
      return Palette.lightPink;
    case "23":
      return Palette.orchid;
    case "24":
      return Palette.mediumPurple;
    default:
      return Colors.grey; // Default color if color ID is not recognized
  }
}
