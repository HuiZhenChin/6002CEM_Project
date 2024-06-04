import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dollar_sense/add_expense_custom_input_view.dart';
import 'package:dollar_sense/add_expense_model.dart';
import 'package:dollar_sense/add_expense_view_model.dart';
import 'package:dollar_sense/currency_input_formatter.dart';
import 'package:image_picker/image_picker.dart';

class ViewExpensesPage extends StatefulWidget {
  final String username;

  const ViewExpensesPage({required this.username});

  @override
  _ViewExpensesPageState createState() => _ViewExpensesPageState();
}

class _ViewExpensesPageState extends State<ViewExpensesPage> {
  late Future<List<Expense>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _expensesFuture = _fetchExpenses();
  }

  Future<List<Expense>> _fetchExpenses() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot expensesSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('expenses')
          .get();

      return expensesSnapshot.docs
          .map((doc) => Expense.fromDocument(doc))
          .toList();
    } else {
    // Return an empty list if no expenses found
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Expenses'),
      ),
      body: FutureBuilder(
        future: _expensesFuture,
        builder: (context, AsyncSnapshot<List<Expense>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.data!.isEmpty) {
            return Center(
              child: Text('No expenses found.'),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final expense = snapshot.data![index];
                return ListTile(
                  title: Text(expense.title),
                  subtitle: Text('Amount: \$${expense.amount}'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Expense Details'),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Title: ${expense.title}'),
                              Text('Amount: \$${expense.amount}'),
                              Text('Category: ${expense.category}'),
                              Text('Payment Method: ${expense.paymentMethod}'),
                              Text('Description: ${expense.description}'),

                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
