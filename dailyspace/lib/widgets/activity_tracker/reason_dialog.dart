import 'package:dailyspace/datastructures/firebase_event.dart';
import 'package:dailyspace/services/firebase_handler.dart';
import 'package:dailyspace/widgets/activity_tracker/delay_timer.dart';
import 'package:dailyspace/widgets/activity_tracker/new_reason.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> reasonDialog(BuildContext context) async {
  FirebaseManager firebaseManager = FirebaseManager();
  Set<String> reasons = Set<String>.from(await firebaseManager.fetchReasons());

  String? selectedReason;
  Duration? selectedDelay;

  final result = await showDialog<Map<String, dynamic>?>(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Why do you want to start later?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Container(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (var reason in reasons)
                    ListTile(
                      title: Text(reason),
                      onTap: () async {
                        selectedReason = reason;
                        selectedDelay = await showDialog<Duration>(
                          context: context,
                          builder: (BuildContext context) => OpenDelayDialog(),
                        );
                        if (selectedDelay != null) {
                          // Close the dialog and return the reason and delay
                          Navigator.pop(dialogContext, {
                            'reason': selectedReason,
                            'delay': selectedDelay
                          });
                        }
                      },
                    ),
                  ListTile(
                    title: const Text('+ New Reason',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final newReason = await showAddReasonDialog(context);
                      if (newReason != null) {
                        reasons.add(newReason);
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );

  return result; // This will return null if the dialog is closed without a selection
}
