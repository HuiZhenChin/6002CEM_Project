import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_expense_model.dart';

class DeleteExpense extends StatelessWidget {
  final Function(Expense) deleteExpense;
  final Expense expense;
  final String username;
  final String documentId;

  const DeleteExpense({
    required this.deleteExpense,
    required this.expense,
    required this.username,
    required this.documentId,
  });

  Future<void> _deleteExpenseFromDatabase() async {
    // Delete the expense from Firestore using documentId
    await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(username)
        .collection('expenses')
        .doc(documentId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Expense'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Are you sure you want to delete this expense?'),
            ElevatedButton(
              onPressed: () async {
                await _deleteExpenseFromDatabase();
                deleteExpense(expense); // Send back the deleted expense
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
