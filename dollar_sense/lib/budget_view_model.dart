import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'budget_model.dart';

class BudgetViewModel {
  TextEditingController categoryController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addBudget(Function(Budget) onBudgetAdded, String username,
      BuildContext context) async {
    String category = categoryController.text.trim();
    double amount = double.tryParse(amountController.text.trim()) ?? 0.0;

    if (category.isNotEmpty && amount > 0) {
      // Check if the category already exists for the user
      bool categoryExists = await checkCategoryExists(username, category);
      if (categoryExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category already exists')),
        );
        return;
      }

      Budget newBudget = Budget(
        category: category,
        amount: amount,
      );

      await _saveBudgetToFirestore(newBudget, username, context);
      onBudgetAdded(newBudget);
      categoryController.clear();
      amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New Budget Added!')),
      );
    } else {
      String errorMessage = (category.isEmpty)
          ? 'Please enter a category'
          : 'Amount must be greater than zero';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

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
            .collection('budget')
            .where('budget_category', isEqualTo: category)
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
          'budget_category': budget.category,
          'budget_amount': budget.amount,
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