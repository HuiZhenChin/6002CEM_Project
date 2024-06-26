import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'budget_notifications_model.dart';

//budget notifications view model
class BudgetNotificationsViewModel {
  TextEditingController categoryController = TextEditingController();
  TextEditingController reminderTypeController = TextEditingController();
  TextEditingController firstReminderController = TextEditingController();
  TextEditingController secondReminderController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //insert budget notifications to database
  Future<void> addBudgetNotifications(Function(BudgetNotifications) onBudgetNotificationsAdded, String username, BuildContext context) async {
    String category = categoryController.text;
    String reminderType = reminderTypeController.text;
    String firstReminder = firstReminderController.text;
    String secondReminder = secondReminderController.text;

    bool categoryExists = await checkCategoryExists(username, category);
    if (categoryExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category already set notifications')),
      );
      return;
    }

      DocumentReference counterDoc = FirebaseFirestore.instance
          .collection('counters')
          .doc('budgetNotificationsCounter');

      DocumentSnapshot counterSnapshot = await counterDoc.get();

      int newBudgetNotificationsId = 1;
      if (counterSnapshot.exists) {
        newBudgetNotificationsId = counterSnapshot['currentId'] as int;
        newBudgetNotificationsId++; // Increment by 1
      }

      // Update the counter document with the new currentId
      await counterDoc.set({'currentId': newBudgetNotificationsId});


      // Create new expense object
    BudgetNotifications newBudgetNotifications = BudgetNotifications(
        id: newBudgetNotificationsId.toString(),
        category: category,
        reminderType: reminderType,
        firstReminder: firstReminder,
        secondReminder: secondReminder,
      );

      // Add the expense using the callback
      onBudgetNotificationsAdded(newBudgetNotifications);

      // Save the expense to Firestore
      await _saveBudgetNotificationsToFirestore(newBudgetNotifications, username, context);

      // Clear form fields
      categoryController.clear();
      reminderTypeController.clear();
      firstReminderController.clear();
      secondReminderController.clear();

    }

    //check whether that category has set notifications before
  Future<bool> checkCategoryExists(String username, String category) async {
    try {
      QuerySnapshot userSnapshot = await _firestore
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('budgetNotifications')
            .where('budgetNotifications_category', isEqualTo: category)
            .get();

        return budgetSnapshot.docs.isNotEmpty;
      } else {
        return false; // User not found
      }
    } catch (e) {
      print('Error checking category existence: $e');
      return true; // Assume category exists to prevent adding duplicate budgets
    }
  }

  //save changes to database
  Future<void> _saveBudgetNotificationsToFirestore(BudgetNotifications budgetNotifications, String username, BuildContext context) async {
    // Query Firestore to get the user ID from the username
    QuerySnapshot userSnapshot = await _firestore
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      CollectionReference budgetNotificationsCollection = FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budgetNotifications');

      Map<String, dynamic> budgetNotificationsData = {
        'budgetNotifications_id': budgetNotifications.id,
        'budgetNotifications_category': budgetNotifications.category,
        'budgetNotifications_reminder_type': budgetNotifications.reminderType,
        'budgetNotifications_first_reminder': budgetNotifications.firstReminder,
        'budgetNotifications_second_reminder': budgetNotifications.secondReminder,
      };


      await budgetNotificationsCollection.add(budgetNotificationsData);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not found')),
      );
    }


  }

}
