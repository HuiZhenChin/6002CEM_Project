import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'budget_model.dart';

//create new budget view model
class BudgetViewModel {
  TextEditingController categoryController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController monthController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //insert new budget to database
  Future<void> addBudget(Function(Budget) onBudgetAdded, String username, BuildContext context) async {
    String category = categoryController.text.trim();
    double amount = double.tryParse(amountController.text.trim()) ?? 0.0;
    String month = monthController.text.trim();
    String year = yearController.text.trim();

    if (category.isNotEmpty && amount > 0 && month.isNotEmpty && year.isNotEmpty) {
      // Check if the category already exists for the user
      bool categoryExists = await checkExists(username, category, month, year);
      if (categoryExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Budget entry for this category, month, and year already exists')),
        );
        return;
      }

      DocumentReference counterDoc = FirebaseFirestore.instance
          .collection('counters')
          .doc('budgetCounter');

      DocumentSnapshot counterSnapshot = await counterDoc.get();

      int newBudgetId = 1;
      if (counterSnapshot.exists) {
        newBudgetId = counterSnapshot['currentId'] as int;
        newBudgetId++; // Increment by 1
      }

      // Update the counter document with the new currentId
      await counterDoc.set({'currentId': newBudgetId});

      Budget newBudget = Budget(
        id: newBudgetId.toString(),
        category: category,
        amount: amount,
        month: month,
        year: year,
      );

      await _saveBudgetToFirestore(newBudget, username, context);
      onBudgetAdded(newBudget);
      categoryController.clear();
      amountController.clear();
      monthController.clear();
      yearController.clear();
    }
  }

  //check whether the specific category for particular month and year already set a budget
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

  //save changes to database
  Future<void> _saveBudgetToFirestore(Budget budget, String username, BuildContext context) async {
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
            .collection('budget');

        Map<String, dynamic> budgetData = {
          'budget_id': budget.id,
          'budget_category': budget.category,
          'budget_amount': budget.amount,
          'budget_month': budget.month,
          'budget_year': budget.year,
        };

        await budgetCollection.add(budgetData);
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
