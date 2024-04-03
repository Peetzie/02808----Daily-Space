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
        log('Failed to fetch task lists -- Status code: ${response.statusCode}');
        return {};
      }
    } else {
      return {};
    }
  }

  static Future<Map<String, Map<String, dynamic>>> fetchTasksForList(
      GoogleSignInAccount? account) async {
    final tasks = <String, Map<String, dynamic>>{};

    final lists = await fetchLists(account);

    for (final entry in lists.entries) {
      final fetchedTasks =
          await _fetchTasksForList(account, entry.value, entry.key);
      tasks.addAll(fetchedTasks);
    }

    return tasks;
  }

  static Future<Map<String, Map<String, dynamic>>> _fetchTasksForList(
      GoogleSignInAccount? account, String listId, String listName) async {
    if (account != null) {
      final authHeaders = await account.authHeaders;
      final googleHttpClient = GoogleHttpClient(authHeaders);
      final url = Uri.parse(
          'https://tasks.googleapis.com/tasks/v1/lists/$listId/tasks');

      final response = await googleHttpClient.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print(_parseTasksResponse(data, listName, listId));
        return _parseTasksResponse(data, listName, listId);
      } else {
        log('Failed to fetch tasks for list $listName -- Status code: ${response.statusCode}');
        return {};
      }
    } else {
      return {};
    }
  }

  static Map<String, Map<String, dynamic>> _parseTasksResponse(
      dynamic response, String listName, String listId) {
    List items = response['items'];
    Map<String, Map<String, dynamic>> tasksDictionary = {};

    for (var item in items) {
      String taskId = item['id'];
      String title = item['title'];
      String updated = item['updated'];
      String notes = item['notes'] ?? "";
      String due = item['due'] ?? "";

      // Associate task with list name and list ID
      tasksDictionary[taskId] = {
        'title': title,
        'updated': updated,
        'notes': notes,
        'due': due,
        'listName': listName,
        'listId': listId,
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
