import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'calendar_notifications_model.dart';

class CalendarNotificationsViewModel {
  TextEditingController reminderTypeController = TextEditingController();
  TextEditingController firstReminderController = TextEditingController();
  TextEditingController secondReminderController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCalendarNotifications(Function(CalendarNotifications) onCalendarNotificationsAdded, String username, BuildContext context) async {
    String reminderType = reminderTypeController.text;
    String firstReminder = firstReminderController.text;
    String secondReminder = secondReminderController.text;

    DocumentReference counterDoc = FirebaseFirestore.instance
        .collection('counters')
        .doc('calendarNotificationsCounter');

    DocumentSnapshot counterSnapshot = await counterDoc.get();

    int newCalendarNotificationsId = 1;
    if (counterSnapshot.exists) {
      newCalendarNotificationsId = counterSnapshot['currentId'] as int;
      newCalendarNotificationsId++; // Increment by 1
    }

    // Update the counter document with the new currentId
    await counterDoc.set({'currentId': newCalendarNotificationsId});


    // Create new expense object
    CalendarNotifications newCalendarNotifications = CalendarNotifications(
      id: newCalendarNotificationsId.toString(),
      reminderType: reminderType,
      firstReminder: firstReminder,
      secondReminder: secondReminder,
    );

    // Add the expense using the callback
    onCalendarNotificationsAdded(newCalendarNotifications);

    // Save the expense to Firestore
    await _saveCalendarNotificationsToFirestore(newCalendarNotifications, username, context);

    // Clear form fields
    reminderTypeController.clear();
    firstReminderController.clear();
    secondReminderController.clear();

  }

  Future<bool> checkCategoryExists(String username, String category) async {
    try {
      QuerySnapshot userSnapshot = await _firestore
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        QuerySnapshot calendarSnapshot = await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('calendarNotifications')
            .where('calendarNotifications_category', isEqualTo: category)
            .get();

        return calendarSnapshot.docs.isNotEmpty;
      } else {
        return false; // User not found
      }
    } catch (e) {
      print('Error checking category existence: $e');
      return true; // Assume category exists to prevent adding duplicate budgets
    }
  }

  Future<void> _saveCalendarNotificationsToFirestore(CalendarNotifications calendarNotifications, String username, BuildContext context) async {
    // Query Firestore to get the user ID from the username
    QuerySnapshot userSnapshot = await _firestore
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      CollectionReference calendarNotificationsCollection = FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('calendarNotifications');

      Map<String, dynamic> calendarNotificationsData = {
        'budgetNotifications_id': calendarNotifications.id,
        'budgetNotifications_reminder_type': calendarNotifications.reminderType,
        'budgetNotifications_first_reminder': calendarNotifications.firstReminder,
        'budgetNotifications_second_reminder': calendarNotifications.secondReminder,
      };


      await calendarNotificationsCollection.add(calendarNotificationsData);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not found')),
      );
    }


  }

}
