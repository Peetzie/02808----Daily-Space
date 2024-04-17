import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailyspace/custom_classes/firebase_event.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> addFirebaseEvent(FirebaseEvent event) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .doc(event.taskId) // Specify the document ID explicitly here
        .set(event.toMap())
        .then(
            (value) => log("Event added successfully with ID: ${event.taskId}"))
        .catchError((error) => log("Failed to add event: $error"));
  } else {
    log("User is not authenticated");
  }
}

Future<void> addUser() {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Reference to the user's document in the 'Users' collection with the UID as the document ID
    DocumentReference userDoc = firestore.collection('users').doc(user.uid);

    // Set minimal user data in this document, such as a creation timestamp
    return userDoc
        .set({
          'createdAt': FieldValue
              .serverTimestamp(), // Sets the timestamp at which the document was created
        })
        .then((value) => log("User record created successfully!"))
        .catchError((error) => log("Failed to create user record: $error"));
  } else {
    log("User is not authenticated");
    throw Exception('User is not authenticated');
  }
}
