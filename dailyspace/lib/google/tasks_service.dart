import 'dart:convert';
import 'dart:developer';

import 'package:dailyspace/google/google_http_client.dart';
import 'package:google_sign_in/google_sign_in.dart';

class TaskService {
  static Future<Map<String, Object>> fetchCalendars(
      GoogleSignInAccount? account) async {
    if (account != null) {
      final authHeaders = await account.authHeaders;
      final googleHttpClient = GoogleHttpClient(authHeaders);
      final url = Uri.parse(
          'https://www.googleapis.com/calendar/v3/users/me/calendarList');

      final response = await googleHttpClient.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return _parseListResponse(data);
      } else {
        log('Failed to fetch task lists -- Status code: ${response.statusCode}');
        return {};
      }
    } else {
      return {};
    }
  }

  static Future<Map<String, Map<String, dynamic>>> fetchTasksFromCalendar(
      GoogleSignInAccount? account, Set<String> selectedCalendars) async {
    final tasks = <String, Map<String, dynamic>>{};
    // log(selectedCalendars.toString());

    final calendars = await fetchCalendars(account);

    for (final selectedCalendar in selectedCalendars) {
      for (final event in calendars.entries) {
        final calendarKey = event.key;
        if (calendarKey == selectedCalendar) {
          final tasksFromCalendar = await _fetchTasksFromCalendar(
            account,
            (event.value as Map<String, dynamic>)['id'],
            calendarKey,
            (event.value as Map<String, dynamic>)['colorId'],
          );
          tasks.addAll(tasksFromCalendar);
          break; // Stop searching for tasks once the selected calendar is found
        }
      }
    }
    return tasks;
  }

  static Future<Map<String, Map<String, dynamic>>> _fetchTasksFromCalendar(
      GoogleSignInAccount? account,
      String calendarId,
      String calendarName,
      String colorId) async {
    if (account != null) {
      final authHeaders = await account.authHeaders;
      final googleHttpClient = GoogleHttpClient(authHeaders);
      final url = Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/${calendarId}/events');

      final response = await googleHttpClient.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        return _parseTasksResponse(data, calendarName, calendarId, colorId);
      } else {
        log('Failed to fetch tasks for list $calendarName -- Status code: ${response.statusCode}');
        return {};
      }
    } else {
      return {};
    }
  }

  static Map<String, Map<String, dynamic>> _parseTasksResponse(dynamic response,
      String calendarName, String calendarId, String colorId) {
    List items = response['items'];

    Map<String, Map<String, dynamic>> tasksDictionary = {};
    for (var item in items) {
      // Check if the "status" key exists in the item
      if (item.containsKey('status') && item['status'] == 'cancelled') {
        // Skip cancelled tasks
        continue;
      }

      log(item.toString());
      String taskId = item['id'] ?? "";
      String title = item['summary'] ?? "";
      String updated = item['updated'] ?? "";
      String notes = item['description'] ?? "";
      // Check if the event has a specific time or just a date
      String start = item['start']['dateTime'] ?? (item['start']['date'] ?? "");
      String end = item['end']['dateTime'] ?? (item['end']['date'] ?? "");

      // Associate task with list name and list ID
      tasksDictionary[taskId] = {
        'taskId': taskId,
        'title': title,
        'updated': updated,
        'notes': notes,
        'start': start,
        'end': end,
        'calendarName': calendarName,
        'calendarID': calendarId,
        'colorId': colorId
      };
    }
    log(tasksDictionary.toString());
    return tasksDictionary;
  }

  static Map<String, Map<String, dynamic>> _parseListResponse(
      dynamic response) {
    List items = response['items'];
    Map<String, Map<String, dynamic>> titlesWithIDsAndColorIds = {};

    for (var item in items) {
      String title = item['summary'];
      String id = item['id'];
      String colorId = item['colorId'];

      // Create a map to store ID and colorID for each title
      Map<String, dynamic> idAndColorId = {
        'id': id,
        'colorId': colorId,
      };

      titlesWithIDsAndColorIds[title] = idAndColorId;
    }

    return titlesWithIDsAndColorIds;
  }
}
