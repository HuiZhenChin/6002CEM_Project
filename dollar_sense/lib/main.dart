<<<<<<< Updated upstream
=======
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/income.dart';
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:dollar_sense/home_page_card.dart';
import 'package:dollar_sense/main_card.dart';
import 'package:dollar_sense/navigation_bar.dart';
import 'package:dollar_sense/add_expense.dart';
import 'add_expense_view_model.dart';
import 'add_expense_model.dart';
import 'package:firebase_core/firebase_core.dart';
<<<<<<< Updated upstream

void main() {
  runApp(MyApp());
}
=======
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dollar_sense/my_account.dart';
import 'package:dollar_sense/income.dart';
import 'package:dollar_sense/income_view_model.dart';
>>>>>>> Stashed changes

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _bottomNavIndex = 0;
  List<Expense> expenses = [];
<<<<<<< Updated upstream
=======
  double _totalExpenses = 0.0;
  double _income= 0.0;
>>>>>>> Stashed changes

  double get totalExpenses {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  void _addExpense(Expense expense) {
    setState(() {
      expenses.add(expense);
    });
<<<<<<< Updated upstream
  }

  void _updateExpenses(List<Expense> updatedExpenses) {
=======
    _fetchTotalExpenses();
  }

  double get income {
    return _income;
  }

  set income(double value) {
    setState(() {
      _income = value;
    });
  }


  @override
  void initState() {
    super.initState();
    _fetchTotalExpenses();
    _fetchIncome();
  }

  void _onTabTapped(int index) {
>>>>>>> Stashed changes
    setState(() {
      expenses = updatedExpenses;
    });
  }


  Future<void> _fetchIncome() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        double incomeValue = userDoc['income'] ?? 0.0;
        setState(() {
          income = incomeValue;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
<<<<<<< Updated upstream
        '/addExpense': (context) => AddExpensePage(onExpenseAdded: _addExpense), // Pass the callback function
        // Other routes...
=======
        '/addExpense': (context) => AddExpensePage(onExpenseAdded: _addExpense, username: widget.username), // Pass the callback function
        '/income': (context) => IncomePage(username: widget.username, onIncomeUpdated: _fetchIncome),
>>>>>>> Stashed changes
      },
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFFAE5CC),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFAE5CC),
                Color(0xFF9F8A85),
                Color(0xFF655C56),
              ],
            ),
          ), // Set screen background color
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: IconButton(
                        icon: Icon(Icons.attach_money),
                        iconSize: 30,
                        onPressed: () {
                          // Implement action for money converter
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: IconButton(
                        icon: Icon(Icons.history),
                        iconSize: 30,
                        onPressed: () {
                          // Implement action for history
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Hey, user',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Card for displaying current net worth
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: MainCard(
                  title: "Current Net Worth",
                  amount: '31758.88',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: HomePageCard(
                            title: 'Income',
                            amount: income.toStringAsFixed(2),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: HomePageCard(
                            title: 'Expense',
                            amount: totalExpenses.toStringAsFixed(2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: HomePageCard(
                            title: 'Budget',
                            amount: '8,500.00',
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: HomePageCard(
                            title: 'Invest',
                            amount: '5,000.00',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Builder(
            builder: (context) {
              return SpeedDial(
                icon: Icons.add,
                activeIcon: Icons.close,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white70,
                overlayColor: Colors.black54,
                overlayOpacity: 0.5,
                children: [
                  SpeedDialChild(
                    child: Icon(Icons.attach_money),
                    backgroundColor: Colors.red,
                    label: 'Income',
                    onTap: () {
                      Navigator.pushNamed(context, '/income');
                    },
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.format_list_bulleted_sharp),
                    backgroundColor: Colors.green,
                    label: 'Expense',
                    onTap: () {
                      Navigator.pushNamed(context, '/addExpense');
                    },
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.calculate_outlined),
                    backgroundColor: Colors.blue,
                    label: 'Budget',
                    onTap: () {

                    },
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.auto_graph),
                    backgroundColor: Colors.orange,
                    label: 'Invest',
                    onTap: () => print('Invest'),
                  ),
                ],
              );
            }
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: CustomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTabTapped: (index) => setState(() {
            _bottomNavIndex = index;
          }),
        ).build(),
      ),
    );
  }
}


