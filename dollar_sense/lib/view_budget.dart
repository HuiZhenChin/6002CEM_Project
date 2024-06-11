import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/budget_notifications.dart';
import 'package:dollar_sense/budget_notifications_model.dart';
import 'package:dollar_sense/budget_view_model.dart';
import 'package:dollar_sense/edit_budget.dart';
import 'package:dollar_sense/edit_budget_notifications.dart';
import 'package:flutter/material.dart';
import 'add_expense_model.dart';
import 'budget_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';
import 'transaction_history_view_model.dart';
import 'budget_notifications_model.dart';

class ViewBudgetPage extends StatefulWidget {
  final String username;

  const ViewBudgetPage({required this.username});

  @override
  _ViewBudgetPageState createState() => _ViewBudgetPageState();
}

class _ViewBudgetPageState extends State<ViewBudgetPage> {
  int currentIndex = 0;
  final navigationBarViewModel= NavigationBarViewModel();
  int _bottomNavIndex = 0;
  List<Budget> budgets = [];
  Map<String, bool> categoryNotifications = {};

  final viewModel = BudgetViewModel();
  final historyViewModel = TransactionHistoryViewModel();
  List<BudgetNotifications> budgetNotificationsList = [];
  List<String> categoriesWithNotificationsButNoBudget = [];

  @override
  void initState() {
    super.initState();

    categoriesWithNotificationsButNoBudget = [];

    // Fetch and initialize budget and notifications data
    _fetchBudget().then((fetchedBudgets) async {
      setState(() {
        budgets = fetchedBudgets;
      });

      for (var budget in fetchedBudgets) {
        BudgetNotifications? notifications = await _fetchNotificationsForBudget(budget);
        if (notifications != null) {
          setState(() {
            budgetNotificationsList.add(notifications);
          });
        }
      }

      // Populate categoryNotifications map
      setState(() {
        for (var notification in budgetNotificationsList) {
          categoryNotifications[notification.category] = true;
        }
      });

      // Fetch categories with notifications but no budget
      var categoriesWithoutBudget = await _fetchCategoriesWithNotificationsButNoBudget();
      setState(() {
        categoriesWithNotificationsButNoBudget = categoriesWithoutBudget;
      });
    });
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
      return [];
    }
  }

  Future<BudgetNotifications?> _fetchNotificationsForBudget(Budget budget) async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;

      QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budgetNotifications')
          .where('budgetNotifications_category', isEqualTo: budget.category)
          .limit(1)
          .get();

      if (notificationsSnapshot.docs.isNotEmpty) {
        return BudgetNotifications.fromDocument(notificationsSnapshot.docs.first);
      }
    }
    return null;
  }



  void _updateBudget(Budget editedBudget) {
    setState(() {
      int index = budgets.indexWhere((budget) => budget.id == editedBudget.id);
      if (index != -1) {
        budgets[index] = editedBudget;
      }
    });
  }

  void _editBudget(Budget budget) async {
    String documentId = await _getDocumentId(budget);
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

    if (editedBudget != null) {
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
      QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budget')
          .where('budget_id', isEqualTo: budget.id)
          .limit(1)
          .get();

      if (budgetSnapshot.docs.isNotEmpty) {
        return budgetSnapshot.docs.first.id;
      }
    }
    return '';
  }

  Future<void> _deleteBudget(Budget budget) async {
    bool? confirmDelete = await _showConfirmationDialog(context, 'delete', budget);
    if (confirmDelete == true) {
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
            .doc(documentId)
            .delete();

        setState(() {
          budgets.removeWhere((element) => element.id == budget.id);
        });

        String specificText = "Delete Budget: ${budget.category} with ${budget.amount}";
        await historyViewModel.addHistory(specificText, widget.username, context);
      }
    }
  }

  Future<bool?> _showConfirmationDialog(BuildContext context, String action, dynamic item) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Background color of the dialog
          title: Text('Confirm $action'),
          content: Text('Are you sure you want to $action this ${item.runtimeType.toString().toLowerCase()}?'),
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

      Map<String, double> categoryExpenses = {};
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
      return {};
    }
  }

  void handleBudgetNotificationsAdded(
      BudgetNotifications newBudgetNotifications) {
    print('New budget notifications added: $newBudgetNotifications');
  }

  void _updateBudgetNotifications(
      BudgetNotifications editedBudgetNotifications) {
    setState(() {
      int index = budgetNotificationsList.indexWhere((budgetNotifications) =>
      budgetNotifications.id == editedBudgetNotifications.id);
      if (index != -1) {
        budgetNotificationsList[index] = editedBudgetNotifications;
      }
    });
  }


  Future<String> _getNotificationsDocumentId(
      BudgetNotifications budgetNotifications) async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot budgetNotificationsSnapshot = await FirebaseFirestore
          .instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budgetNotifications')
          .where('budgetNotifications_id', isEqualTo: budgetNotifications.id)
          .limit(1)
          .get();

      if (budgetNotificationsSnapshot.docs.isNotEmpty) {
        return budgetNotificationsSnapshot.docs.first.id;
      }
    }
    return '';
  }

  Future<void> _deleteBudgetNotifications(
      BudgetNotifications budgetNotifications) async {
      String username = widget.username;
      String documentId = await _getNotificationsDocumentId(budgetNotifications);
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('budgetNotifications')
            .doc(documentId)
            .delete();

        setState(() {
          budgetNotificationsList.removeWhere((element) =>
          element.id == budgetNotifications.id);
        });
      }
  }

  void refreshData() async {
    for (var budget in budgets) {
      BudgetNotifications? notifications = await _fetchNotificationsForBudget(budget);
      if (notifications != null) {
        setState(() {
          // Update the notifications for the given budget
          categoryNotifications[budget.category] = true;
        });
      } else {
        setState(() {
          // Remove the notifications for the given budget if there are none
          categoryNotifications.remove(budget.category);
        });
      }
    }
  }

  Future<List<String>> _fetchCategoriesWithNotificationsButNoBudget() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;

      // Fetch budget categories
      QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budget')
          .get();

      Set<String> budgetCategories = budgetSnapshot.docs
          .map((doc) => doc['budget_category'] as String)
          .toSet();

      // Fetch budget notification categories
      QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budgetNotifications')
          .get();

      Set<String> notificationCategories = notificationsSnapshot.docs
          .where((doc) => doc['budgetNotifications_category'] != null)
          .map((doc) => doc['budgetNotifications_category'] as String)
          .toSet();

      // Categories that have notifications but no budget
      notificationCategories.removeAll(budgetCategories);

      return notificationCategories.toList();
    } else {
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('View Budget'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              refreshData();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEEF4F8),
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
                    child: Text(
                      'No budgets found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
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
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.notification_add_rounded),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BudgetNotificationsPage(
                                          username: widget.username,
                                          onBudgetNotificationsAdded:
                                          handleBudgetNotificationsAdded,
                                        ),
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
                'Total Amount: ${totalAmount?.toStringAsFixed(2) ?? 'N/A'}'),
          ),
        );
      },
    );
  }

  Widget _buildBudgetList(List<Budget> budgets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            final isOdd = index % 2 == 0;
            final hasNotification = categoryNotifications[budget.category] ?? false;

            return GestureDetector(
              onTap: () {
                _handleBudgetCategoryTap(context, budget);
              },
              child: Container(
                color: isOdd ? Colors.grey[200]!.withOpacity(0.8) : Colors.white!.withOpacity(0.8),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(budget.category),
                          if (hasNotification)
                            Icon(
                              Icons.notifications,
                              color: Color(0xffd3746c),
                              size: 16.0,
                            ),
                        ],
                      ),
                      Text(
                        '${budget.month}, ${budget.year}',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  subtitle: Text('Amount: ${budget.amount.toStringAsFixed(2)}'),
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
              ),
            );
          },
        ),
        SizedBox(height: 16.0),
        // Categories with notifications but no budget
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Categories with notifications but no budget: ${categoriesWithNotificationsButNoBudget.join(', ')}',
            style: TextStyle(fontSize: 16, color: Color(0xffd3746c)),
          ),
        ),
      ],
    );
  }

  void _handleBudgetCategoryTap(BuildContext context, Budget budget) async {
    BudgetNotifications? budgetNotifications = await _fetchNotificationsForBudget(budget);
    if (budgetNotifications != null) {
      String documentId = await _getNotificationsDocumentId(budgetNotifications);

      // Show a dialog or navigate to another page to handle edit/delete options
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Budget Category Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Modify Notifications'),
                  onTap: () {
                    // Navigate to modify notifications page
                    _navigateToModifyNotificationsPage(context, budgetNotifications, documentId);
                  },
                ),
                ListTile(
                  title: Text('Delete Notifications'),
                  onTap: () {
                    // Delete notifications logic here
                    _deleteNotifications(budgetNotifications);
                    Navigator.pop(context); // Close the dialog
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }


  void _navigateToModifyNotificationsPage(BuildContext context, BudgetNotifications budgetNotifications, String documentId) {
    // Navigate to modify notifications page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBudgetNotifications(
          onBudgetNotificationsUpdated: _updateBudgetNotifications,
          username: widget.username,
          budgetNotifications: budgetNotifications,
          documentId: documentId,
        ),
      ),
    );
  }


  void _deleteNotifications(BudgetNotifications budgetNotifications) {
   _deleteBudgetNotifications(budgetNotifications);
  }
}