import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'budget_model.dart';
import 'budget_notifications.dart';
import 'add_expense_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';
import 'budget_notifications_model.dart';

class NotificationsPage extends StatefulWidget {
  final String username;

  const NotificationsPage({required this.username});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<BudgetNotifications> budgetNotificationsList = [];
  Map<String, double> categoryExpenses = {};
  Map<String, double> categoryBudgets = {};
  int _bottomNavIndex = 1;
  List<Budget> budgets = [];

  @override
  void initState() {
    super.initState();
    // Call the fetching methods in initState to ensure they're executed only once
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _fetchBudgets();
    await _fetchExpenseCategories();
  }

  Future<void> _fetchNotifications() async {
    try {
      final QuerySnapshot budgetNotificationsSnapshot = await FirebaseFirestore
          .instance
          .collection('dollar_sense')
          .doc(widget.username)
          .collection('budgetNotifications')
          .get();

      setState(() {
        budgetNotificationsList = budgetNotificationsSnapshot.docs
            .map((doc) => BudgetNotifications.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      print('Error fetching notifications: $e');
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

  Future<void> _fetchBudgets() async {
    try {
      final QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(widget.username)
          .collection('budget')
          .get();

      setState(() {
        categoryBudgets = {};
        budgetSnapshot.docs.forEach((doc) {
          Budget budget = Budget.fromDocument(doc);
          categoryBudgets[budget.category] = budget.amount;
        });
      });
    } catch (e) {
      print('Error fetching budgets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: FutureBuilder(
        future: _fetchBudgets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching data'));
          } else {
            return ListView.builder(
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final double expenseAmount = categoryExpenses[budget
                    .category] ?? 0;
                final double remainingBudget = budget.amount - expenseAmount;

                // Check if both expense and budget amounts are found for the category
                if (expenseAmount > 0 && budget.amount > 0) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment
                            .middle,
                        children: [
                          TableRow(
                            children: [
                              Text('Category', style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                              Text('Expense Amount', style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                              Text('Budget Amount', style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                              Text('Remaining Budget', style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                            ],
                          ),
                          TableRow(
                            children: [
                              Text(budget.category),
                              Text('\$${expenseAmount.toStringAsFixed(2)}'),
                              Text('\$${budget.amount.toStringAsFixed(2)}'),
                              Text('\$${remainingBudget.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Display only budget information if expense or budget amount is not found
                  return ListTile(
                    title: Text(budget.category),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Budget: \$${budget.amount.toStringAsFixed(2)}'),
                      ],
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}