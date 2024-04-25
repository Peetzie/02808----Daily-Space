import 'package:dailyspace/services/firebase_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<String?> showAddReasonDialog(BuildContext context) async {
  TextEditingController textEditingController = TextEditingController();
  FirebaseManager firebaseManager = FirebaseManager();

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Add a new reason'),
        content: TextField(
          controller: textEditingController,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter your reason here'),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              // Only close the dialog and add the reason if the input is not empty
              if (textEditingController.text.trim().isNotEmpty) {
                firebaseManager.addReason(textEditingController.text.trim());
                Navigator.of(context).pop(textEditingController.text.trim());
              }
            },
          ),
        ],
      );
    },
  );
}
