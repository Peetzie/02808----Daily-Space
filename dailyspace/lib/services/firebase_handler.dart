import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailyspace/sources/default_reasons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dailyspace/datastructures/firebase_event.dart';

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
          FirebaseEvent event = FirebaseEvent.fromMap(doc.data());
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

  Future<void> updateDelayedEvent(
      String taskId, FirebaseEvent updatedEvent) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Reference to the document of the delayed event to be updated
        DocumentReference eventDocRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('delayedEvents')
            .doc(taskId);

        // Update the document with the new data provided by updatedEvent
        await eventDocRef
            .update(updatedEvent.toMap())
            .then((_) =>
                log("Delayed event updated successfully for Task ID: $taskId"))
            .catchError(
                (error) => log("Failed to update delayed event: $error"));
      } catch (e) {
        log("Error updating delayed event: ${e.toString()}");
        throw e; // Rethrow the error to be handled by the caller
      }
    } else {
      log("User is not authenticated");
      throw Exception("User is not authenticated");
    }
  }

  Future<FirebaseEvent?> fetchDelayedEvent(String taskId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Query the 'delayedEvents' collection for the specific event by its task ID
        DocumentSnapshot eventDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('delayedEvents')
            .doc(taskId)
            .get();

        if (eventDoc.exists) {
          // If the document exists, convert it to a FirebaseEvent object and return it
          return FirebaseEvent.fromMap(eventDoc.data() as Map<String, dynamic>);
        } else {
          // If the document doesn't exist, return null indicating that the event wasn't found
          return null;
        }
      } catch (e) {
        log("Error fetching delayed event: ${e.toString()}");
        return null; // Return null in case of any error
      }
    } else {
      log("User is not authenticated");
      throw Exception("User is not authenticated");
    }
  }

  Future<Map<String, FirebaseEvent>> fetchDelayedEvents() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        var snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('delayedEvents')
            .where('endedAt', isNull: true)
            .get();

        // Convert the list of DocumentSnapshots to a Map
        Map<String, FirebaseEvent> activeEventsMap = {};
        for (var doc in snapshot.docs) {
          FirebaseEvent event = FirebaseEvent.fromMap(doc.data());
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

  Future<List<String>> fetchReasons() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reasons')
            .get();

        List<String> reasonsList = [];
        for (var doc in snapshot.docs) {
          // Ensure data is non-null and cast to Map<String, dynamic>
          var data = doc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('reason')) {
            String? reason = data['reason'] as String?;
            if (reason != null) {
              reasonsList.add(reason);
            }
          }
        }
        return reasonsList;
      } catch (e) {
        log("Error fetching reasons: ${e.toString()}");
        return []; // Return an empty list in case of error
      }
    } else {
      log("User is not authenticated");
      throw Exception("User is not authenticated");
    }
  }

  Future<void> addDelayedEvent(FirebaseEvent event) async {
    User? user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('delayedEvents')
          .doc(event.taskId) // Specify the document ID explicitly here
          .set(event.toMap())
          .then((value) =>
              log("Event added successfully with ID: ${event.taskId}"))
          .catchError((error) => log("Failed to add event: $error"));
    } else {
      log("User is not authenticated");
    }
  }

  Future<void> addReason(String reason) async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference reasonDoc = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reasons')
          .doc(); // Firestore generates a unique ID for the document

      return reasonDoc
          .set({'reason': reason})
          .then((value) => log("Reason added successfully"))
          .catchError((error) => log("Failed to add reason: $error"));
    } else {
      log("User is not authenticated");
      throw Exception("User is not authenticated");
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
        Set<String> eventIds = <String>{};
        for (var doc in snapshot.docs) {
          eventIds.add(doc.id);
        }
        return eventIds;
      } catch (e) {
        log("Error fetching ended evnet IDs: ${e.toString()}");
        return <String>{};
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
          return <String>{};
        }
      }).catchError((error) {
        log("Failed to fetch selected calendars: $error");
        return <String>{}; // Return an empty set on error
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

      // Begin a batch write to perform multiple writes as a single atomic operation
      WriteBatch batch = _firestore.batch();

      // Set minimal user data in this document, such as a creation timestamp
      batch.set(userDoc, {
        'createdAt': FieldValue
            .serverTimestamp(), // Sets the timestamp at which the document was created
      });

      // Set up default reasons

      // Reference to the reasons sub-collection
      CollectionReference reasonsCol = userDoc.collection('reasons');

      // Add each default reason as a new document in the 'reasons' collection
      for (var reason in defaultReasons) {
        var reasonDoc =
            reasonsCol.doc(); // Automatically generate a new document ID
        batch.set(reasonDoc, {'reason': reason});
      }

      // Commit the batch write to Firestore
      await batch
          .commit()
          .then((value) =>
              log("User record and default reasons created successfully!"))
          .catchError((error) =>
              log("Failed to create user record and default reasons: $error"));

      // Check if the 'reasons' sub-collection was created
      await userDoc.collection('reasons').doc().get().then((docSnapshot) {
        if (!docSnapshot.exists) {
          log("Warning: 'reasons' sub-collection was not created.");
        }
      });
    } else {
      log("User is not authenticated");
      throw Exception('User is not authenticated');
    }
  }
}
