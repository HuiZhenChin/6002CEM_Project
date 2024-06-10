import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/budget.dart';
import 'package:dollar_sense/notifications.dart';
import 'package:intl/intl.dart';
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
import 'currency_converter_model.dart';

class MyApp extends StatefulWidget {
  final String username;
  MyApp({required this.username});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final navigationBarViewModel = NavigationBarViewModel();
  int _bottomNavIndex = 0;
  List<Expense> expenses = [];
  List<Invest> invests = [];
  List<Budget> budgets = [];
  List<Currency> currencyList = [];
  double _totalExpenses = 0.0;
  double _income = 0.0;
  double _totalInvest = 0.0;
  double _totalBudget = 0.0;
  double _currentNetWorth = 0.0;
  bool _hasUnreadNotifications = false;
  int unreadNotificationsCount = 0;

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

  void _currency(Currency currency) {
    setState(() {
      currencyList.add(currency);
    });
    _fetchCurrency();
  }

  @override
  void initState() {
    super.initState();
    _fetchTotalExpenses();
    _fetchIncome();
    _fetchTotalInvest();
    _fetchTotalBudget();
    _fetchCurrentNetWorth();
    _fetchAndStoreData();
    _retrieveRemainingAmountAndScheduleNotifications();
    fetchNotifications(widget.username);
    _fetchCurrency();
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
    await _fetchAndStoreData();
    await _retrieveRemainingAmountAndScheduleNotifications();
    await fetchNotifications(widget.username);
    await _fetchCurrency();
  }


  Future<void> _fetchAndStoreData() async {
    try {
      String username = widget.username;
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;

        // Month name to number mapping
        Map<String, String> monthMapping = {
          'january': '01',
          'february': '02',
          'march': '03',
          'april': '04',
          'may': '05',
          'june': '06',
          'july': '07',
          'august': '08',
          'september': '09',
          'october': '10',
          'november': '11',
          'december': '12'
        };

        // Fetch and store budget
        QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('budget')
            .get();

        Map<String, double> budgetMap = {};
        Set<String> budgetCategories = {};
        for (var doc in budgetSnapshot.docs) {
          double budgetAmount = doc['budget_amount'] as double;
          String budgetCategory = doc['budget_category'] as String;
          String month = doc['budget_month'] as String;
          String year = doc['budget_year'] as String;
          String monthNumber = monthMapping[month.toLowerCase()]!;
          String monthYear = '${budgetCategory}_${monthNumber}_${year}';
          String documentId = monthYear;

          budgetMap[budgetCategory] = budgetAmount;
          budgetCategories.add(budgetCategory);

          // Store budget amount in notifications collection
          await FirebaseFirestore.instance
              .collection('dollar_sense')
              .doc(userId)
              .collection('notifications')
              .doc(documentId)
              .set({
            'budget_amount': budgetAmount,
            'category': budgetCategory,
            'month': monthNumber,
            'year': year,
          },
              SetOptions(merge: true));
        }

        // Fetch and accumulate expenses by category
        Map<String,
            Map<String,
                double>> categoryExpenses = await _fetchExpenseCategories(
            userId);

        // Store expenses in notifications collection if there's a corresponding budget category
        for (var entry in categoryExpenses.entries) {
          String expenseCategory = entry.key;
          Map<String, double> monthlyExpenses = entry.value;

          for (var monthYearEntry in monthlyExpenses.entries) {
            String monthYear = monthYearEntry.key;
            double totalExpenseAmount = monthYearEntry.value;
            String documentId = '${expenseCategory}_$monthYear';

            if (budgetMap.containsKey(expenseCategory)) {
              await FirebaseFirestore.instance
                  .collection('dollar_sense')
                  .doc(userId)
                  .collection('notifications')
                  .doc(documentId)
                  .set({'expense_amount': totalExpenseAmount},
                  SetOptions(merge: true));
            }
          }
        }

        // Fetch and store budget notifications
        QuerySnapshot budgetNotificationsSnapshot = await FirebaseFirestore
            .instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('budgetNotifications')
            .get();

        String currentMonthYear = DateFormat('MM_yyyy').format(DateTime.now());

        for (var doc in budgetNotificationsSnapshot.docs) {
          String category = doc['budgetNotifications_category'];
          String firstReminder = doc['budgetNotifications_first_reminder'];
          String secondReminder = doc['budgetNotifications_second_reminder'];
          String documentId = '${category}_$currentMonthYear';

          // Check if the category exists in the budget categories set
          if (budgetCategories.contains(category)) {
            await FirebaseFirestore.instance
                .collection('dollar_sense')
                .doc(userId)
                .collection('notifications')
                .doc(documentId)
                .set({
              'budgetNotifications_first_reminder': firstReminder,
              'budgetNotifications_second_reminder': secondReminder,
            }, SetOptions(merge: true));
          }
        }
      }
    } catch (e) {
      print('Error in _fetchAndStoreData: $e');
    }
  }

  Future<Map<String, Map<String, double>>> _fetchExpenseCategories(
      String userId) async {
    try {
      QuerySnapshot expenseSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('expenses')
          .get();

      Map<String, Map<String, double>> categoryExpenses = {};
      DateFormat dateFormat = DateFormat('dd-MM-yyyy');
      for (var doc in expenseSnapshot.docs) {
        double expenseAmount = doc['amount'] as double;
        String expenseCategory = doc['category'] as String;
        DateTime expenseDate = dateFormat.parse(doc['date']);
        String monthYear = DateFormat('MM_yyyy').format(expenseDate);

        if (!categoryExpenses.containsKey(expenseCategory)) {
          categoryExpenses[expenseCategory] = {};
        }

        if (categoryExpenses[expenseCategory]!.containsKey(monthYear)) {
          categoryExpenses[expenseCategory]![monthYear] =
              categoryExpenses[expenseCategory]![monthYear]! + expenseAmount;
        } else {
          categoryExpenses[expenseCategory]![monthYear] = expenseAmount;
        }
      }

      return categoryExpenses;
    } catch (e) {
      print('Error in _fetchExpenseCategories: $e');
      return {};
    }
  }

  Future<void> _retrieveRemainingAmountAndScheduleNotifications() async {
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
          .collection('notifications')
          .get();

      List<String> reminderMessages = [];
      int firstUnreadReminderCount = 0;
      int secondUnreadReminderCount = 0;

      for (var doc in notificationsSnapshot.docs) {
        // Get the document data as a map
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if the map contains all the required keys
        if (data.containsKey('budget_amount') &&
            data.containsKey('expense_amount') &&
            data.containsKey('budgetNotifications_first_reminder') &&
            data.containsKey('budgetNotifications_second_reminder')) {
          double budgetAmount = data['budget_amount'] as double;
          double expenseAmount = data['expense_amount'] as double;
          String category = data['category'];
          String month = data['month'];
          String year = data['year'];
          String firstReminder = data['budgetNotifications_first_reminder'];
          String secondReminder = data['budgetNotifications_second_reminder'];
          bool readFirstReminder = data['read_first_reminder'] ?? false;
          bool readSecondReminder = data['read_second_reminder'] ?? false;

          // Calculate the remaining amount and the percentage of the budget that has been used
          double remainingAmount = budgetAmount - expenseAmount;
          double usedBudgetPercentage = (expenseAmount / budgetAmount) * 100;

          // Update the document with the remaining budget
          String documentId = '${category}_${month}_${year}';
          await FirebaseFirestore.instance
              .collection('dollar_sense')
              .doc(userId)
              .collection('notifications')
              .doc(documentId)
              .update({'remaining_budget': remainingAmount});

          // Schedule notifications based on remaining amount and reminders
          if (!readFirstReminder &&
              usedBudgetPercentage >= double.parse(firstReminder)) {
            // Add first reminder message
            reminderMessages.add(
                'First Reminder: You have used $usedBudgetPercentage% of your budget, which is more than $firstReminder%.');
            firstUnreadReminderCount++; // Increment unread reminder count
            await FirebaseFirestore.instance
                .collection('dollar_sense')
                .doc(userId)
                .collection('notifications')
                .doc(documentId)
                .update({'read_first_reminder': false});
          }
          if (!readSecondReminder && expenseAmount > budgetAmount) {
            // Add second reminder message
            reminderMessages.add(
                'Second Reminder: You have exceeded your budget.');
            secondUnreadReminderCount++; // Increment unread reminder count
            await FirebaseFirestore.instance
                .collection('dollar_sense')
                .doc(userId)
                .collection('notifications')
                .doc(documentId)
                .update({'read_second_reminder': false});
          }
        }
      }

      int totalCount = firstUnreadReminderCount + secondUnreadReminderCount;

      // Show a single dialog with all reminder messages
      if (reminderMessages.isNotEmpty) {
        String message = reminderMessages.join('\n');
        await _scheduleNotification(
            userId, 'notification_id', message, totalCount);
      }
    }
  }

  Future<void> _scheduleNotification(String userId, String docId,
      String message, int totalCount) async {
    // Ensure the context is available and show a pop-up dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context, // Ensure you have access to the BuildContext
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Notification"),
            content: Text(
                "You have $totalCount unread reminder(s) in Notifications"),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }


  Future<void> fetchNotifications(String username) async {
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('notifications')
          .get();

      int unreadFirstReminderCount = 0;
      int unreadSecondReminderCount = 0;

      for (var doc in notificationsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('category') &&
            data.containsKey('month') &&
            data.containsKey('year')) {
          String documentId = '${data['category']}_${data['month']}_${data['year']}';

          if (data.containsKey('read_first_reminder') &&
              data['read_first_reminder'] == false) {
            unreadFirstReminderCount++;
          }

          if (data.containsKey('read_second_reminder') &&
              data['read_second_reminder'] == false) {
            unreadSecondReminderCount++;
          }
        }
      }

      setState(() {
        _hasUnreadNotifications =
        (unreadFirstReminderCount > 0 || unreadSecondReminderCount > 0);
        unreadNotificationsCount =
            unreadFirstReminderCount + unreadSecondReminderCount;
      });
    }
  }

  Future<void> _fetchCurrency() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      CollectionReference currencyCollection = FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('currency');

      QuerySnapshot currencySnapshot = await currencyCollection.get();

      if (currencySnapshot.docs.isNotEmpty) {
        DocumentReference currencyDocRef = currencySnapshot.docs.first
            .reference;
        DocumentSnapshot currencyDocSnapshot = await currencyDocRef.get();

        if (currencyDocSnapshot.exists) {
          double currencyRate = currencyDocSnapshot['rate'];
          bool converted = currencyDocSnapshot['converted'];

          if (!converted) {
            // Update all collections with new currency rates
            await _updateAllCollections(userId, currencyRate, currencyDocRef);

            // Set the currency document's 'converted' field to true
            await currencyDocRef.update({'converted': true});

            // Refresh total budget and income after currency conversion
            await _fetchTotalBudget(); // Assuming _fetchTotalBudget fetches and sets the total budget
            await _fetchIncome(); // Assuming _fetchIncome fetches and sets the income
          }
        }
      }
    }
  }


  Future<void> _updateAllCollections(String userId, double currencyRate,
      DocumentReference currencyDocRef) async {
    QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(userId)
        .collection('budget')
        .get();

    for (var doc in budgetSnapshot.docs) {
      double budgetAmount = doc['budget_amount'];
      double convertedBudgetAmount = budgetAmount * currencyRate;
      await doc.reference.update({'budget_amount': convertedBudgetAmount});
    }

    QuerySnapshot investSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(userId)
        .collection('invest')
        .get();

    for (var doc in investSnapshot.docs) {
      double investAmount = doc['invest_amount'];
      double convertedInvestAmount = investAmount * currencyRate;
      await doc.reference.update({'invest_amount': convertedInvestAmount});
    }

    QuerySnapshot expenseSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(userId)
        .collection('expenses')
        .get();

    for (var doc in expenseSnapshot.docs) {
      double expenseAmount = doc['amount'];
      double convertedExpenseAmount = expenseAmount * currencyRate;
      await doc.reference.update({'amount': convertedExpenseAmount});
    }

    QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(userId)
        .collection('notifications')
        .get();

    for (var doc in notificationsSnapshot.docs) {
      double budget = doc['budget_amount'];
      double expense = doc['expense_amount'];
      double convertedBudget = budget * currencyRate;
      double convertedExpense = expense * currencyRate;
      await doc.reference.update({
        'budget_amount': convertedBudget,
        'expense_amount': convertedExpense
      });
    }

    // Fetch user document to update income
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(userId)
        .get();

    if (userSnapshot.exists) {
      double income = (userSnapshot.data() as Map<String, dynamic>?)?['income'] as double? ?? 0.0;
      double convertedIncome = income * currencyRate;
      await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .update({
        'income': convertedIncome
      }); // Update income directly in the user document
    }
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/income': (context) =>
            IncomePage(
                username: widget.username, onIncomeUpdated: _fetchIncome),
        '/invest': (context) =>
            InvestPage(username: widget.username, onInvestAdded: _addInvest),
        '/addExpenses': (context) =>
            AddExpensePage(
                onExpenseAdded: _addExpense, username: widget.username),
        '/profile': (context) => MyAccount(username: widget.username),
        '/budget': (context) =>
            BudgetPage(username: widget.username, onBudgetAdded: _addBudget),
        '/history': (context) =>
            TransactionHistoryPage(username: widget.username),
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications),
                            iconSize: 30,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      NotificationsPage(username: widget.username),
                                ),
                              );
                            },
                          ),
                          if (_hasUnreadNotifications)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: Text(
                                  '$unreadNotificationsCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
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
                                      CurrencyConverterPage(
                                          username: widget.username, onCurrencyAdded: _currency,),
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
                                      TransactionHistoryPage(
                                          username: widget.username),
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
          onTabTapped: NavigationBarViewModel.onTabTapped(
              context, widget.username),
        ).build(),
      ),
    );
  }
}