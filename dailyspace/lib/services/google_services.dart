/*
  Created by: 
  - Frederik Peetz-Schou Larsen
  As part of course 02808 at DTU 2024. 
*/
import 'dart:convert';
import 'dart:developer';

import 'package:dailyspace/services/google_http_client.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleServices {
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

  static Future<void> createAndUpdateCalendar(GoogleSignInAccount? account,
      Map<String, int> calendarData, bool colorRgbFormat) async {
    if (account != null) {
      final authHeaders = await account.authHeaders;
      final googleHttpClient = GoogleHttpClient(authHeaders);
      const baseUrl = 'https://www.googleapis.com/calendar/v3/calendars';

      for (final entry in calendarData.entries) {
        final name = entry.key;
        final colorId = entry.value;

        final url = Uri.parse(baseUrl);
        final requestBody = {'summary': name};
        final response = await googleHttpClient.post(
          url,
          body: json.encode(requestBody),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          print("Calendar '$name' created successfully.");
          final data = json.decode(response.body);
          final calendarId = data['id']; // Extracting calendar ID from response

          // Prepare to update the color
          final updateUrl = Uri.parse(
              'https://www.googleapis.com/calendar/v3/users/me/calendarList/$calendarId');
          final updateBody = json.encode({
            'colorId': colorId.toString(),
            'colorRgbFormat':
                colorRgbFormat // Indicating whether color ID is in RGB format
          });

          final updateResponse = await googleHttpClient.put(
            updateUrl,
            body: updateBody,
            headers: {'Content-Type': 'application/json'},
          );

          if (updateResponse.statusCode == 200) {
            print("Calendar color updated successfully for '$name'.");
          } else {
            print(
                "Failed to update calendar color for '$name'. Status code: ${updateResponse.statusCode}");
          }
        } else {
          print(
              "Failed to create calendar '$name'. Status code: ${response.statusCode}");
        }
      }
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
          'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events');

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
