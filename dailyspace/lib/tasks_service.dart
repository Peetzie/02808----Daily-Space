import 'dart:convert';
import 'dart:developer';

import 'package:dailyspace/google_http_client.dart';
import 'package:google_sign_in/google_sign_in.dart';

class TaskService {
  static Future<Map<String, String>> fetchLists(
      GoogleSignInAccount? account) async {
    if (account != null) {
      final authHeaders = await account.authHeaders;
      final googleHttpClient = GoogleHttpClient(authHeaders);
      final url =
          Uri.parse('https://tasks.googleapis.com/tasks/v1/users/@me/lists');

      final response = await googleHttpClient.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print(_parseListResponse(data));
        return _parseListResponse(data);
      } else {
        log('Failed to fetch tasks -- Status code: ${response.statusCode}');
        return {};
      }
    } else {
      return {};
    }
  }

  static Future<Map<String, Map<String, dynamic>>> fetchTasks(
      GoogleSignInAccount? account) async {
    if (account != null) {
      final authHeaders = await account.authHeaders;
      final googleHttpClient = GoogleHttpClient(authHeaders);
      final url = Uri.parse(
          'https://tasks.googleapis.com/tasks/v1/lists/MDA0NDMxNTc1MjM2MjQwNTA1NzQ6MDow/tasks');

      final response = await googleHttpClient.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print(_parseTasksResponse(data));
        return _parseTasksResponse(data);
      } else {
        log('Failed to fetch tasks -- Status code: ${response.statusCode}');
        return {};
      }
    } else {
      return {};
    }
  }

  static Map<String, Map<String, dynamic>> _parseTasksResponse(
      dynamic response) {
    List items = response['items'];
    Map<String, Map<String, dynamic>> tasksDictionary = {};

    for (var item in items) {
      String id = item['id'];
      String title = item['title'];
      String updated = item['updated'];
      String notes = item['notes'] ?? "";
      String due = item['due'] ?? "";

      tasksDictionary[id] = {
        'title': title,
        'updated': updated,
        'notes': notes,
        'due': due
      };
    }
    return tasksDictionary;
  }

  static Map<String, String> _parseListResponse(dynamic response) {
    List items = response['items'];
    Map<String, String> titlesWithIDs = {};

    for (var item in items) {
      String title = item['title'];
      String id = item['id'];
      titlesWithIDs[title] = id;
    }

    return titlesWithIDs;
  }
}
