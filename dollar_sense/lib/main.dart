import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/view_expenses.dart';
import 'package:dollar_sense/income.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:dollar_sense/home_page_card.dart';
import 'package:dollar_sense/main_card.dart';
import 'package:dollar_sense/navigation_bar.dart';
import 'package:dollar_sense/add_expense.dart';
import 'add_expense_view_model.dart';
import 'add_expense_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dollar_sense/my_account.dart';
import 'package:dollar_sense/income.dart';
import 'package:dollar_sense/income_view_model.dart';
import 'package:dollar_sense/invest.dart';
import 'package:dollar_sense/invest_view_model.dart';
import 'package:dollar_sense/invest_model.dart';
import 'package:dollar_sense/speed_dial.dart';

class MyApp extends StatefulWidget {

  final String username, email;
  MyApp({required this.username, required this.email});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _bottomNavIndex = 0;
  List<Expense> expenses = [];
  List<Invest> invests = [];
  double _totalExpenses = 0.0;
  double _income= 0.0;
  double _totalInvest = 0.0;

  double get totalExpenses {
    return _totalExpenses;
  }

  set totalExpenses(double value) {
    setState(() {
      _totalExpenses = value;
    });
  }


  void _addExpense(Expense expense) {
    setState(() {
      expenses.add(expense);
    });
    _fetchTotalExpenses();
  }

  void _addInvest(Invest invest) {
    setState(() {
      invests.add(invest);
    });
    _fetchTotalInvest();
  }

  double get income {
    return _income;
  }

  set income(double value) {
    setState(() {
      _income = value;
    });
  }

  double get totalInvest {
    return _totalInvest;
  }

  set totalInvest(double value) {
    setState(() {
      _totalInvest = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchTotalExpenses();
    _fetchIncome();
    _fetchTotalInvest();
  }

  void _onTabTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyAccount(username: widget.username, email: widget.email),
        ),
      );
    }
  }

  Future<void> _fetchTotalExpenses() async {
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

      double total = 0.0;
      expensesSnapshot.docs.forEach((doc) {
        total += doc['amount'] as double;
      });

      setState(() {
        totalExpenses = total;
      });
    }
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

  Future<void> _fetchTotalInvest() async {
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
          .collection('invest')
          .get();

      double total = 0.0;
      expensesSnapshot.docs.forEach((doc) {
        total += doc['invest_amount'] as double;
      });

      setState(() {
        totalInvest = total;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/income': (context) => IncomePage(username: widget.username, onIncomeUpdated: _fetchIncome),
        '/invest': (context) => InvestPage(username: widget.username, onInvestAdded: _addInvest, email: widget.email ),
        '/addExpenses': (context) => AddExpensePage(onExpenseAdded: _addExpense, username: widget.username),
        '/profile': (context) => MyAccount(username: widget.username, email: widget.email),
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
                Color(0xFF6E655E),
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
                  'Hey, ${widget.username}',
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
                            amount: totalInvest.toStringAsFixed(2),
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
        floatingActionButton: CustomSpeedDial(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: CustomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTabTapped: _onTabTapped,
        ).build(),
      ),
    );
  }
}
