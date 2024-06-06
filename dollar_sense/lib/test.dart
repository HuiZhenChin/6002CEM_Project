import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dollar_sense/add_expense_custom_input_view.dart';
import 'package:dollar_sense/add_expense_model.dart';
import 'package:dollar_sense/add_expense_view_model.dart';
import 'package:dollar_sense/currency_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dollar_sense/navigation_bar.dart';
import 'package:dollar_sense/my_account.dart';
import 'package:dollar_sense/edit_expense.dart';

class TestPage extends StatefulWidget {
  final String username;

  const TestPage({required this.username});

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _defaultImageBase64 = "";
  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    _loadDefaultImage();
    _fetchExpenses();
  }

  Future<void> _loadDefaultImage() async {
    _defaultImageBase64 = await loadDefaultImageAsBase64();
  }

  Future<String> loadDefaultImageAsBase64() async {
    final ByteData bytes = await rootBundle.load('assets/expenses.png');
    final Uint8List list = bytes.buffer.asUint8List();
    return base64Encode(list);
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
          .orderBy('id')
          .get();

      return expensesSnapshot.docs.map((doc) {
        Expense expense = Expense.fromDocument(doc);
        // Don't override the receiptImage if it's already set in Firestore
        if (expense.receiptImage == null && (expense.imageBase64 == null || expense.imageBase64!.isEmpty)) {
          return Expense(
            id: expense.id,
            title: expense.title,
            amount: expense.amount,
            category: expense.category,
            paymentMethod: expense.paymentMethod,
            description: expense.description,
            date: expense.date,
            time: expense.time,
            receiptImage: null,
            imageBase64: expense.imageBase64, // Keep the original value from Firestore
          );
        }
        return expense;
      }).toList();
    } else {
      // Return an empty list if no expenses found
      return [];
    }
  }


  Widget _buildExpenseImage(Expense expense) {
    if (expense.receiptImage != null || expense.imageBase64 != null) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Receipt Picture'),
                content: Container(
                  width: 300,
                  height: 300,
                  child: InteractiveViewer(
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.1,
                    maxScale: 4,
                    scaleEnabled: true,
                    child: _getImageWidget(expense),
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Close'),
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _getImageWidget(expense),
        ),
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox.shrink(), // Empty container
      );
    }
  }

  Widget _getImageWidget(Expense expense) {
    if (expense.receiptImage != null) {
      if (kIsWeb) {
        return Image.network(
          expense.receiptImage!.path,
          height: 100,
          width: 100,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          expense.receiptImage!,
          height: 100,
          width: 100,
          fit: BoxFit.cover,
        );
      }
    } else if (expense.imageBase64 != null && expense.imageBase64!.isNotEmpty) {
      return Image.memory(
        base64Decode(expense.imageBase64!),
        height: 100,
        width: 100,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey,
        child: Center(
          child: Text('No Image'),
        ),
      );
    }
  }

  Future<bool?> _showConfirmationDialog(BuildContext context, String action) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm $action'),
          content: Text('Are you sure you want to $action this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _updateExpense(Expense editedExpense) {
    setState(() {
      // Find the index of the edited expense in the expenses list
      int index = expenses.indexWhere((expense) => expense.id == editedExpense.id);
      if (index != -1) {
        // Replace the edited expense with the new one
        expenses[index] = editedExpense;
      }
    });
  }

  void _editExpense(Expense expense) async {
    // Retrieve the document ID associated with the selected expense
    String documentId = await _getDocumentId(expense);

    // Navigate to the edit expense screen and pass the document ID
    Expense editedExpense = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpense(
          onExpenseUpdated: _updateExpense,
          expense: expense,
          username: widget.username,
          documentId: documentId,
        ),
      ),
    );

    // Check if an expense was edited
    if (editedExpense != null) {
      // Update the UI with the edited expense
      _updateExpense(editedExpense);
    }
  }


  Future<String> _getDocumentId(Expense expense) async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot expenseSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('expenses')
          .where('title', isEqualTo: expense.title) // Assuming 'title' is unique, adjust if needed
          .limit(1)
          .get();

      if (expenseSnapshot.docs.isNotEmpty) {
        return expenseSnapshot.docs.first.id; // Return the document ID
      }
    }
    // Return an empty string or handle the case where the document ID is not found
    return '';
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF988E82),
        title: Text('View Expenses'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF988E82),
              Color(0xFFDED2C4),
              Color(0xFFD5C2B0),
            ],
          ),
        ),
        child: FutureBuilder<List<Expense>>(
          future: _fetchExpenses(),
          builder: (context, snapshot) {
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
                  final isOdd = index % 2 == 0; // Check if the index is odd

                  return Dismissible(
                    key: Key(expense.title.toString()), // Unique key for each item
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.blue,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.edit, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // Handle delete action
                        return await _showConfirmationDialog(context, "delete");
                      } else {
                        // Handle edit action
                        _editExpense(expense);
                        return false;
                      }
                    },
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        // Remove the item from the data source
                        setState(() {
                          snapshot.data!.removeAt(index);
                        });
                      }
                    },
                    child: Container(
                      color: isOdd
                          ? Colors.grey[200]!.withOpacity(0.8)
                          : Colors.white!.withOpacity(
                          0.8), // Set background color based on index
                      child: ListTile(
                        leading: _buildExpenseImage(expense),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(expense.title),
                            Text(
                              'Category: ${expense.category}',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        subtitle: Text('Amount: \RM${expense.amount}'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Color(0xFFE3CCB2),
                                title: Text('Expense Details'),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: 8),
                                    Text('Title: ${expense.title}'),
                                    SizedBox(height: 8),
                                    Text('Amount: \$${expense.amount}'),
                                    SizedBox(height: 8),
                                    Text('Category: ${expense.category}'),
                                    SizedBox(height: 8),
                                    Text(
                                        'Payment Method: ${expense.paymentMethod}'),
                                    SizedBox(height: 8),
                                    Text('Description: ${expense.description}'),
                                    SizedBox(height: 8),
                                    Text('Date: ${expense.date}'),
                                    SizedBox(height: 8),
                                    Text('Time: ${expense.time}'),
                                    SizedBox(height: 8),
                                    Center(child: _buildExpenseImage(expense)),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                    },
                                    child: Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
