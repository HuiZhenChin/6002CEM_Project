import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'calendar_model.dart';
import 'calendar.dart';

class BudgetViewModel {
  TextEditingController monthController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCalendar(Function(Calendar) onCalendarAdded, String username, BuildContext context) async {
    String month = monthController.text.trim();
    String year = yearController.text.trim();

      DocumentReference counterDoc = FirebaseFirestore.instance
          .collection('counters')
          .doc('calendarCounter');

      DocumentSnapshot counterSnapshot = await counterDoc.get();

      int newCalendarId = 1;
      if (counterSnapshot.exists) {
        newCalendarId = counterSnapshot['currentId'] as int;
        newCalendarId++; // Increment by 1
      }

      // Update the counter document with the new currentId
      await counterDoc.set({'currentId': newCalendarId});

      Calendar newCalendar = Calendar(
        id: newCalendarId.toString(),
        month: month,
        year: year,
      );

      await _saveBudgetToFirestore(newCalendar, username, context);
      onCalendarAdded(newCalendar);
      monthController.clear();
      yearController.clear();
    }
  }

  Future<bool> checkExists(String username, String category, String month, String year) async {
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
            .collection('budget')
            .where('budget_category', isEqualTo: category)
            .where('budget_month', isEqualTo: month)
            .where('budget_year', isEqualTo: year)
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

  Future<void> _saveBudgetToFirestore(Calendar calendar, String username, BuildContext context) async {
    try {
      QuerySnapshot userSnapshot = await _firestore
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        CollectionReference budgetCollection = FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('calendar');

        Map<String, dynamic> calendarData = {
          'calendar_id': calendar.id,
          'calendar_month': calendar.month,
          'calendar_year': calendar.year,
        };

        await calendarCollection.add(calendarData);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
