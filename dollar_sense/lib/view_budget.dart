import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/budget_notifications.dart';
import 'package:dollar_sense/budget_notifications_model.dart';
import 'package:dollar_sense/edit_budget.dart';
import 'package:flutter/material.dart';
import 'budget_model.dart';
import 'package:flutter/services.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';
import 'transaction_history_view_model.dart';
import 'budget_view_model.dart';
import 'add_expense_model.dart';

class ViewBudgetPage extends StatefulWidget {
  final String username;

  const ViewBudgetPage({required this.username});

  @override
  _ViewBudgetPageState createState() => _ViewBudgetPageState();
}

class _ViewBudgetPageState extends State<ViewBudgetPage> {
  int currentIndex = 0;
  int _bottomNavIndex = 0;
  List<Budget> budgets = [];
  final viewModel = BudgetViewModel();
  final historyViewModel = TransactionHistoryViewModel();
  List<BudgetNotifications> budgetNotifications = [];

  @override
  void initState() {
    super.initState();
    _fetchBudget();
  }

  Future<List<Budget>> _fetchBudget() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budget')
          .orderBy('budget_id')
          .get();

      return budgetSnapshot.docs
          .map((doc) => Budget.fromDocument(doc))
          .toList();
    } else {
      // Return an empty list if no budget found
      return [];
    }
  }

  void _updateBudget(Budget editedBudget) {
    setState(() {
      // Find the index of the edited expense in the expenses list
      int index =
      budgets.indexWhere((budget) => budget.id == editedBudget.id);
      if (index != -1) {
        // Replace the edited expense with the new one
        budgets[index] = editedBudget;
      }
    });
  }

  void _editBudget(Budget budget) async {
    // Retrieve the document ID associated with the selected expense
    String documentId = await _getDocumentId(budget);

    // Navigate to the edit expense screen and pass the document ID
    Budget editedBudget = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditBudget(
              onBudgetUpdated: _updateBudget,
              username: widget.username,
              budget: budget,
              documentId: documentId,
            ),
      ),
    );

    // Check if an expense was edited
    if (editedBudget != null) {
      // Update the UI with the edited expense
      _updateBudget(editedBudget);
    }
  }

  Future<String> _getDocumentId(Budget budget) async {
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
          .collection('budget')
          .where('budget_id', isEqualTo: budget.id)
          .limit(1)
          .get();

      if (expenseSnapshot.docs.isNotEmpty) {
        return expenseSnapshot.docs.first.id;
      }
    }
    // Return an empty string or handle the case where the document ID is not found
    return '';
  }

  Future<void> _deleteBudget(Budget budget) async {
    String username = widget.username;
    String documentId = await _getDocumentId(budget);
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budget')
          .doc(documentId) // Specify the document ID of the investment to delete
          .delete();

      setState(() {
        // Remove the deleted investment from the list
        budgets.removeWhere((element) => element.id == budget.id);
      });

      // Add the history entry with the title of the deleted investment
      String specificText = "Delete Budget: ${budget.category} with ${budget
          .amount}";
      await historyViewModel.addHistory(specificText, widget.username, context);
    }
  }

  Future<Map<String, double>> _fetchExpenseCategories() async {
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
          .get();

      // Initialize a map to store total expenses by category
      Map<String, double> categoryExpenses = {};

      // Loop through each expense and accumulate expenses by category
      expenseSnapshot.docs.forEach((doc) {
        Expense expense = Expense.fromDocument(doc);
        if (categoryExpenses.containsKey(expense.category)) {
          categoryExpenses[expense.category] =
              (categoryExpenses[expense.category] ?? 0) + expense.amount;
        } else {
          categoryExpenses[expense.category] = expense.amount;
        }
      });

      return categoryExpenses;
    } else {
      // Return an empty map if no expenses found
      return {};
    }
  }

  void handleBudgetNotificationsAdded(BudgetNotifications newBudgetNotifications) {
    // Add your logic here to handle the addition of budget notifications
    // For example, you can update the UI, save the notifications to a local database, etc.
    print('New budget notifications added: $newBudgetNotifications');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF988E82),
        title: Text('View Budget'),
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
        child: ListView(
          children: [

            FutureBuilder<List<Budget>>(
              future: _fetchBudget(),
              builder: (context, budgetSnapshot) {
                if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (budgetSnapshot.data == null ||
                    budgetSnapshot.data!.isEmpty) {
                  return Center(
                    child: Text('No budget found.'),
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Budget Categories',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_notifications_rounded),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                       BudgetNotificationsPage(username: widget.username, onBudgetNotificationsAdded: handleBudgetNotificationsAdded,),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      _buildBudgetList(budgetSnapshot.data!),
                    ],
                  );
                }
              },
            ),


            SizedBox(height: 16.0),
            // Expense Categories Section
            FutureBuilder<Map<String, double>>(
              future: _fetchExpenseCategories(),
              builder: (context, expenseSnapshot) {
                if (expenseSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (expenseSnapshot.data == null ||
                    expenseSnapshot.data!.isEmpty) {
                  return Center(
                    child: Text('No expenses found.'),
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Expense Categories',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildCategoryList(expenseSnapshot.data!, 'expenses'),
                    ],
                  );
                }
              },
            ),
          ],
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

// Helper method to build the category list for expenses
  Widget _buildCategoryList(Map<String, double> categories, String type) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.toList()[index];
        final totalAmount = categories[category];
        final isOdd = index % 2 == 0;

        return Container(
          color: isOdd
              ? Colors.grey[200]!.withOpacity(0.8)
              : Colors.white!.withOpacity(0.8),
          child: ListTile(
            title: Text(category),
            subtitle: Text(
                'Total Amount: RM${totalAmount?.toStringAsFixed(2) ?? 'N/A'}'),
          ),
        );
      },
    );
  }

// Helper method to build the list for budgets
  Widget _buildBudgetList(List<Budget> budgets) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        final isOdd = index % 2 == 0;

        return Container(
          color: isOdd
              ? Colors.grey[200]!.withOpacity(0.8)
              : Colors.white!.withOpacity(0.8),
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(budget.category),
                Text(
                  '${budget.month}, ${budget.year}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            subtitle: Text('Amount: RM${budget.amount.toStringAsFixed(2)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _editBudget(budget);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    _deleteBudget(budget);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}