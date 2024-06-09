import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/budget.dart';
import 'add_category.dart';
import 'income.dart';
import 'package:flutter/material.dart';
import 'home_page_card.dart';
import 'main_card.dart';
import 'navigation_bar.dart';
import 'add_expense.dart';
import 'add_expense_model.dart';
import 'my_account.dart';
import 'invest.dart';
import 'invest_model.dart';
import 'speed_dial.dart';
import 'budget.dart';
import 'budget_model.dart';
import 'transaction_history.dart';
import 'navigation_bar_view_model.dart';
import 'currency_converter.dart';

class MyApp extends StatefulWidget {
  final String username;
  MyApp({required this.username});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _bottomNavIndex = 0;
  List<Expense> expenses = [];
  List<Invest> invests = [];
  List<Budget> budgets = [];
  double _totalExpenses = 0.0;
  double _income = 0.0;
  double _totalInvest = 0.0;
  double _totalBudget= 0.0;
  double _currentNetWorth= 0.0;

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

  void _addBudget(Budget budget) {
    setState(() {
      budgets.add(budget);
    });
    _fetchTotalBudget();
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

  double get totalBudget {
    return _totalBudget;
  }

  set totalBudget(double value) {
    setState(() {
      _totalBudget = value;
    });
  }

  double get currentNetWorth {
    return _currentNetWorth;
  }

  set currentNetWorth(double value) {
    setState(() {
      _currentNetWorth = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchTotalExpenses();
    _fetchIncome();
    _fetchTotalInvest();
    _fetchTotalBudget();
    _fetchCurrentNetWorth();
  }

  void _onTabTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MyAccount(username: widget.username),
        ),
      );
    }
    else if (index == 2) {

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
      QuerySnapshot investSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('invest')
          .get();

      double total = 0.0;
      investSnapshot.docs.forEach((doc) {
        total += doc['invest_amount'] as double;
      });

      setState(() {
        totalInvest = total;
      });
    }
  }

  Future<void> _fetchTotalBudget() async {
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
          .get();

      double total = 0.0;
      budgetSnapshot.docs.forEach((doc) {
        total += doc['budget_amount'] as double;
      });

      setState(() {
        totalBudget = total;
      });
    }
  }

  Future<void> _fetchCurrentNetWorth() async {
    // Fetch income, expenses, and budget
    await _fetchIncome();
    await _fetchTotalExpenses();
    await _fetchTotalInvest();

    // Calculate net worth
    double netWorth = income - totalExpenses - totalInvest;

    // Set the calculated net worth to the _currentNetWorth variable
    setState(() {
      _currentNetWorth = netWorth;
    });
  }


  Future<void> _refreshData() async {
    await _fetchTotalExpenses();
    await _fetchIncome();
    await _fetchTotalInvest();
    await _fetchTotalBudget();
    await _fetchCurrentNetWorth();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/income': (context) => IncomePage(username: widget.username, onIncomeUpdated: _fetchIncome),
        '/invest': (context) => InvestPage(username: widget.username, onInvestAdded: _addInvest ),
        '/addExpenses': (context) => AddExpensePage(onExpenseAdded: _addExpense, username: widget.username),
        '/profile': (context) => MyAccount(username: widget.username),
        '/budget': (context) => BudgetPage(username: widget.username, onBudgetAdded: _addBudget,),
        '/history': (context) => TransactionHistoryPage(username: widget.username),
        '/category': (context) => AddCategoryPage(username: widget.username),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CurrencyConverterPage(username: widget.username),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: IconButton(
                        icon: Icon(Icons.history),
                        iconSize: 30,
                        onPressed: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (context) =>
                            TransactionHistoryPage(username: widget.username),
                            ),
                            );
                            },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: IconButton(
                        icon: Icon(Icons.refresh),
                        iconSize: 30,
                        onPressed: () {
                          _refreshData();
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
                  amount: _currentNetWorth.toStringAsFixed(2),
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
                            amount: totalBudget.toStringAsFixed(2),
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
          onTabTapped: NavigationBarViewModel.onTabTapped(context, widget.username),
        ).build(),
      ),
    );
  }
}