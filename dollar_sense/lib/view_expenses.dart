import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/add_expense_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'add_expense_model.dart';
import 'package:flutter/services.dart';
import 'package:dollar_sense/edit_expense.dart';
import 'transaction_history_view_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class ViewExpensesPage extends StatefulWidget {
  final String username;

  const ViewExpensesPage({required this.username});

  @override
  _ViewExpensesPageState createState() => _ViewExpensesPageState();
}

class _ViewExpensesPageState extends State<ViewExpensesPage> {
  String _defaultImageBase64 = "";
  List<Expense> expenses = [];
  final viewModel= AddExpenseViewModel();
  final historyViewModel= TransactionHistoryViewModel();
  final navigationBarViewModel= NavigationBarViewModel();
  int _bottomNavIndex = 0;
  String _currentFilter = 'None';
  bool _isFiltered = false;


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

  deleteToDoTask(Expense expense) {
    expenses.removeWhere((element) => element.id == expense.id);
    setState(() {});
  }

  Future<void> _deleteExpense(Expense expense) async {
    bool? confirmed = await _showConfirmationDialog(context, 'delete', expense);
    if (confirmed != true) {
      return; // User cancelled the deletion
    }
    String username = widget.username;
    String documentId = await _getDocumentId(expense);
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('expenses')
          .doc(documentId)
          .delete();

      setState(() {
        expenses.removeWhere((element) => element.id == expense.id);
      });

      String specificText = "Delete Expenses: ${expense.title} ";
      await historyViewModel.addHistory(specificText, widget.username, context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense deleted successfully'),
        ),
      );
    }
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
        if (expense.receiptImage == null &&
            (expense.imageBase64 == null || expense.imageBase64!.isEmpty)) {
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
            imageBase64: _defaultImageBase64,
          );
        }
        return expense;
      }).toList();
    } else {
      return [];
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
          .where('id', isEqualTo: expense.id)
          .limit(1)
          .get();

      if (expenseSnapshot.docs.isNotEmpty) {
        return expenseSnapshot.docs.first.id;
      }
    }
    return '';
  }


  Future<bool?> _showConfirmationDialog(BuildContext context, String action, Expense expense) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Background color of the dialog
          title: Text('Confirm $action'),
          content: Text('Are you sure you want to $action this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Button text color
              ),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Close the dialog and confirm
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // Button text color
              ),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }


  void _updateExpense(Expense editedExpense) {
    setState(() {
      int index = expenses.indexWhere((expense) =>
      expense.id == editedExpense.id);
      if (index != -1) {
        expenses[index] = editedExpense;
      }
    });
  }

  void _editExpense(Expense expense) async {
    String documentId = await _getDocumentId(expense);

    Expense editedExpense = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditExpense(
              onExpenseUpdated: _updateExpense,
              expense: expense,
              username: widget.username,
              documentId: documentId,
            ),
      ),
    );

    if (editedExpense != null) {
      _updateExpense(editedExpense);
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
        child: SizedBox.shrink(),
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

  List<Expense> _filterExpenses(List<Expense> expenses) {
    switch (_currentFilter) {
      case 'Title':
        expenses.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Title (Z-A)':
        expenses.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'Amount (High to Low)':
        expenses.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Amount (Low to High)':
        expenses.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'Category (A-Z)':
        expenses.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'Category (Z-A)':
        expenses.sort((a, b) => b.category.compareTo(a.category));
        break;
      default:
        break;
    }
    return expenses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('View Expenses'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () async {
              String? result = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    backgroundColor: Colors.white,
                    title: Text('Filter Options'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Title');
                        },
                        child: Text('Title (A-Z)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Title (Z-A)');
                        },
                        child: Text('Title (Z-A)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Amount (High to Low)');
                        },
                        child: Text('Amount (High to Low)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Amount (Low to High)');
                        },
                        child: Text('Amount (Low to High)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Category (A-Z)');
                        },
                        child: Text('Category (A-Z)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'Category (Z-A)');
                        },
                        child: Text('Category (A-Z)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'None');
                        },
                        child: Text('Remove Filter'),
                      ),
                    ],
                  );
                },
              );
              if (result != null) {
                setState(() {
                  _currentFilter = result;
                  _isFiltered = _currentFilter != 'None';
                });
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEEF4F8),
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
                child: Text(
                  'No expenses found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            } else {
              List<Expense> filteredExpenses = _isFiltered
                  ? _filterExpenses(snapshot.data!)
                  : snapshot.data!;
              return ListView.builder(
                itemCount: filteredExpenses.length,
                itemBuilder: (context, index) {
                  final expense = filteredExpenses[index];
                  final isOdd = index % 2 == 0; // Check if the index is odd

                  return Container(
                    color: isOdd
                        ? Colors.grey[200]!.withOpacity(0.8)
                        : Colors.white.withOpacity(
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
                      subtitle: Text('Amount: \ ${expense.amount}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editExpense(expense);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteExpense(expense);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Color(0xffa5b4c2),
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
                                      'Payment Method: ${expense
                                          .paymentMethod}'),
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
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped: NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }
}