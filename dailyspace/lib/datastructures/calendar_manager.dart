import 'dart:developer';

import 'package:dailyspace/services/firebase_handler.dart';
import 'package:dailyspace/services/google_services.dart';
import 'package:dailyspace/services/google_sign_in_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CalendarManager {
  GoogleSignInAccount? account;
  List<String> availableCalendars = [];
  Set<String> selectedCalendars = {};

  Future<void> fetchCalendars(GoogleSignInAccount? account) async {
    final calendars = await GoogleServices.fetchCalendars(account);
    availableCalendars.clear();
    availableCalendars.addAll(calendars.keys);
    fetchSelectedCalendars();
  }

  Future<void> fetchSelectedCalendars() async {
    try {
      selectedCalendars = await FirebaseManager().fetchSelectedCalendars();
      log(selectedCalendars.toString());
      // Now `selectedCalendars` is populated with the fetched data
    } catch (e) {
      log("Error fetching calendars: $e");
    }
  }
}
