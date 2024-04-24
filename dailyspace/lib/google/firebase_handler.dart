import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailyspace/custom_classes/helper.dart';
import 'package:dailyspace/custom_classes/taskinfo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dailyspace/custom_classes/firebase_event.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseManager {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFirebaseEvent(FirebaseEvent event) async {
    User? user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activeEvents')
          .doc(event.taskId) // Specify the document ID explicitly here
          .set(event.toMap())
          .then((value) =>
              log("Event added successfully with ID: ${event.taskId}"))
          .catchError((error) => log("Failed to add event: $error"));
    } else {
      log("User is not authenticated");
    }
  }

  Future<Map<String, FirebaseEvent>> fetchActiveEvents() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        var snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('activeEvents')
            .where('endedAt', isNull: true)
            .get();

        // Convert the list of DocumentSnapshots to a Map
        Map<String, FirebaseEvent> activeEventsMap = {};
        for (var doc in snapshot.docs) {
          FirebaseEvent event =
              FirebaseEvent.fromMap(doc.data() as Map<String, dynamic>);
          activeEventsMap[event.taskId] =
              event; // Assume taskId is a unique key for each event
        }

        return activeEventsMap;
      } catch (e) {
        log("Error fetching active events: ${e.toString()}");
        return {}; // Return an empty map in case of error
      }
    } else {
      log("User is not authenticated");
      throw Exception("User is not authenticated");
    }
  }
// Inside FirebaseManager class

  Future<List<FirebaseEvent>> fetchActiveAndEndedEvents() async {
    User? user = _auth.currentUser;
    if (user == null) {
      log("User is not authenticated");
      throw Exception('User is not authenticated');
    }

    List<FirebaseEvent> combinedEventList = [];

    try {
      // Fetch active events
      QuerySnapshot activeEventsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activeEvents')
          .where('endedAt', isNull: true)
          .get();

      for (DocumentSnapshot eventDoc in activeEventsSnapshot.docs) {
        combinedEventList.add(
            FirebaseEvent.fromMap(eventDoc.data() as Map<String, dynamic>));
      }

      // Fetch ended events
      QuerySnapshot endedEventsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('endedEvents')
          .get();

      for (DocumentSnapshot eventDoc in endedEventsSnapshot.docs) {
        combinedEventList.add(
            FirebaseEvent.fromMap(eventDoc.data() as Map<String, dynamic>));
      }

      return combinedEventList;
    } catch (e) {
      log("Error fetching events: ${e.toString()}");
      return []; // Return an empty list in case of error
    }
  }

  Future<void> endEvent(String taskId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference activeEventDoc = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activeEvents')
          .doc(taskId);

      // Fetch the event to be ended
      DocumentSnapshot eventSnapshot = await activeEventDoc.get();
      if (eventSnapshot.exists) {
        Map<String, dynamic> eventData =
            eventSnapshot.data() as Map<String, dynamic>;
        eventData['endedAt'] = FieldValue.serverTimestamp();

        // Copy the ended event to the 'endedEvents' collection
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('endedEvents')
            .doc(taskId)
            .set(eventData);

        // Remove the event from 'activeEvents'
        await activeEventDoc.delete();
        log("Event moved to ended successfully for Task ID: $taskId");
      } else {
        log("Event not found or already ended.");
      }
    } else {
      log("User is not authenticated");
      throw Exception('User is not authenticated');
    }
  }

  Future<List<FirebaseEvent>> fetchAndConvertEndedEvents() async {
    User? user = _auth.currentUser;
    if (user == null) {
      log("User is not authenticated");
      throw Exception('User is not authenticated');
    }
    List<FirebaseEvent> eventList = [];

    QuerySnapshot eventsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('endedEvents')
        .get();
    for (DocumentSnapshot eventDoc in eventsSnapshot.docs) {
      eventList
          .add(FirebaseEvent.fromMap(eventDoc.data() as Map<String, dynamic>));
    }
    return eventList;
  }

  Future<Set<String>> fetchAllEndedEventIds() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        var snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('endedEvents')
            .get();
        Set<String> eventIds = Set<String>();
        for (var doc in snapshot.docs) {
          eventIds.add(doc.id);
        }
        return eventIds;
      } catch (e) {
        log("Error fetching ended evnet IDs: ${e.toString()}");
        return Set<String>();
      }
    } else {
      log("User is not authenticated");
      throw Exception("User is not authenticated");
    }
  }

  Future<void> saveSelectedCalendars(Set<String> selectedCalendars) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Reference to the user's calendars document
      DocumentReference calendarsDoc = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('calendars');

      // Convert the Set to a List for Firebase compatibility
      List<String> calendarList = selectedCalendars.toList();

      // Set the selected calendars in Firestore
      return calendarsDoc
          .set({
            'selectedCalendars': calendarList,
            'updatedAt':
                FieldValue.serverTimestamp() // Timestamp for the update
          })
          .then((value) => log("Selected calendars saved successfully"))
          .catchError(
              (error) => log("Failed to save selected calendars: $error"));
    } else {
      log("User is not authenticated");
      throw Exception('User is not authenticated');
    }
  }

  Future<Set<String>> fetchSelectedCalendars() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Reference to the user's calendars document
      DocumentReference calendarsDoc = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('calendars');

      // Fetch the document
      return calendarsDoc.get().then((docSnapshot) {
        if (docSnapshot.exists && docSnapshot.data() != null) {
          var data = docSnapshot.data()!
              as Map<String, dynamic>; // Cast to Map<String, dynamic>
          List<dynamic> calendars = data['selectedCalendars'];
          // Log the fetched calendars

          // Return the list as a Set of Strings
          return Set<String>.from(
              calendars.map((calendar) => calendar.toString()));
        } else {
          log("No selected calendars data found");
          return Set<String>();
        }
      }).catchError((error) {
        log("Failed to fetch selected calendars: $error");
        return Set<String>(); // Return an empty set on error
      });
    } else {
      log("User is not authenticated");
      throw Exception('User is not authenticated');
    }
  }

  Future<void> addUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Reference to the user's document in the 'Users' collection with the UID as the document ID
      DocumentReference userDoc = _firestore.collection('users').doc(user.uid);

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
}
