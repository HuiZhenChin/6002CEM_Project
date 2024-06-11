import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/budget.dart';
import 'package:dollar_sense/notifications.dart';
import 'package:dollar_sense/view_budget.dart';
import 'package:dollar_sense/view_expenses.dart';
import 'package:dollar_sense/view_invest.dart';
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
import 'package:google_fonts/google_fonts.dart';

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
  String baseCurrency = 'MYR';

  double get totalExpenses => _totalExpenses;

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

  double get income => _income;

  set income(double value) {
    setState(() {
      _income = value;
    });
  }

  double get totalInvest => _totalInvest;

  set totalInvest(double value) {
    setState(() {
      _totalInvest = value;
    });
  }

  double get totalBudget => _totalBudget;

  set totalBudget(double value) {
    setState(() {
      _totalBudget = value;
    });
  }

  double get currentNetWorth => _currentNetWorth;

  set currentNetWorth(double value) {
    setState(() {
      _currentNetWorth = value;
    });
  }

  void _currency(Currency currency) {
    setState(() {
      currencyList.add(currency);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchDataForCurrentMonth();
    //_fetchTotalExpenses();
    //_fetchIncome();
    //_fetchTotalInvest();
    //_fetchTotalBudget();
    //_fetchCurrentNetWorth();
    _fetchAndStoreData();
    _retrieveRemainingAmountAndScheduleNotifications();
    fetchNotifications(widget.username);
    fetchBaseCurrency();
  }

  Future<void> _fetchDataForCurrentMonth() async {
    String username = widget.username;
    String currentMonthNumber = DateFormat('MM').format(DateTime.now());
    String currentYear = DateFormat('yyyy').format(DateTime.now());

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

    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;

        // Fetch invest
        QuerySnapshot investSnapshot = await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('invest')
            .get();

        double totalInvest = 0.0;
        for (var doc in investSnapshot.docs) {
          String dateStr = doc['invest_date'] as String;
          DateTime date = DateFormat('d-M-yyyy').parse(dateStr);
          String investMonthNumber = DateFormat('MM').format(date);
          String investYear = DateFormat('yyyy').format(date);
          if (investMonthNumber == currentMonthNumber &&
              investYear == currentYear) {
            totalInvest += doc['invest_amount'] as double;
          }
        }

        // Fetch budget
        QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('budget')
            .get();

        double totalBudget = 0.0;
        for (var doc in budgetSnapshot.docs) {
          String budgetMonth = doc['budget_month'] as String;
          String budgetYear = doc['budget_year'] as String;
          String budgetMonthNumber = monthMapping[budgetMonth.toLowerCase()]!;
          if (budgetMonthNumber == currentMonthNumber &&
              budgetYear == currentYear) {
            totalBudget += doc['budget_amount'] as double;
          }
        }

        // Fetch expenses
        QuerySnapshot expensesSnapshot = await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('expenses')
            .get();

        double totalExpenses = 0.0;
        for (var doc in expensesSnapshot.docs) {
          String dateStr = doc['date'] as String;
          DateTime date = DateFormat('d-M-yyyy').parse(dateStr);
          String expenseMonthNumber = DateFormat('MM').format(date);
          String expenseYear = DateFormat('yyyy').format(date);
          if (expenseMonthNumber == currentMonthNumber &&
              expenseYear == currentYear) {
            totalExpenses += doc['amount'] as double;
          }
        }

        // Fetch income
        double totalIncome = 0.0;
        QuerySnapshot incomeSnapshot = await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('income')
            .get();

        for (var doc in incomeSnapshot.docs) {
          totalIncome += doc['income'] as double;
        }

        setState(() {
          _totalBudget = totalBudget;
          _totalExpenses = totalExpenses;
          _totalInvest = totalInvest;
          _income = totalIncome;
          _currentNetWorth = totalIncome - totalExpenses - totalInvest;
        });

        // Store the fetched data in a new collection for the current month
        await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('current_month_data')
            .doc('$currentMonthNumber-$currentYear')
            .set({
          'total_budget': totalBudget,
          'total_expenses': totalExpenses,
          'total_invest': totalInvest,
          'total_income': totalIncome,
        });
      }
    } catch (error) {
      print('Error fetching and storing data: $error');
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
      QuerySnapshot incomeSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('income')
          .get();

      double total = 0.0;
      incomeSnapshot.docs.forEach((doc) {
        total += doc['income'] as double;
      });

      setState(() {
        income = total;
      });
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
    //await _fetchTotalExpenses();
    //await _fetchIncome();
    //await _fetchTotalInvest();
    //await _fetchTotalBudget();
    //await _fetchCurrentNetWorth();
    await _fetchDataForCurrentMonth();
    await _fetchAndStoreData();
    await _retrieveRemainingAmountAndScheduleNotifications();
    await fetchNotifications(widget.username);
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
          }, SetOptions(merge: true));
        }

        // Fetch and accumulate expenses by category
        Map<String, Map<String, double>> categoryExpenses =
        await _fetchExpenseCategories(userId);

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
            reminderMessages
                .add('Second Reminder: You have exceeded your budget.');
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
            backgroundColor: Colors.white,
            // Background color of the AlertDialog
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
          String documentId =
              '${data['category']}_${data['month']}_${data['year']}';

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

  Future<void> fetchBaseCurrency() async {
    try {
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
          String baseCurrencyCode = currencySnapshot.docs.first['code'];
          setState(() {
            baseCurrency = baseCurrencyCode;
          });
        } else {
          // If the user does not have a currency collection, set default to MYR 1.00
          setState(() {
            baseCurrency = 'MYR';
          });
        }
      }
    } catch (e) {
      print('Error fetching base currency: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/income': (context) =>
            IncomePage(
              username: widget.username,
              onIncomeUpdated: _fetchIncome,
            ),
        '/invest': (context) =>
            InvestPage(
              username: widget.username,
              onInvestAdded: _addInvest,
            ),
        '/addExpenses': (context) =>
            AddExpensePage(
              onExpenseAdded: _addExpense,
              username: widget.username,
            ),
        '/profile': (context) =>
            MyAccount(
              username: widget.username,
            ),
        '/budget': (context) =>
            BudgetPage(
              username: widget.username,
              onBudgetAdded: _addBudget,
            ),
        '/history': (context) =>
            TransactionHistoryPage(
              username: widget.username,
            ),
        '/category': (context) =>
            AddCategoryPage(
              username: widget.username,
            ),
        '/viewBudget': (context) => ViewBudgetPage(username: widget.username),
        '/viewInvest': (context) => ViewInvestPage(username: widget.username),
        '/viewExpenses': (context) =>
            ViewExpensesPage(username: widget.username),
      },
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFEEF4F8),
          title: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello,',
                    style: TextStyle(
                      fontSize: 12.0, // Adjust the font size as needed
                    ),
                  ),
                  Text(
                    widget.username,
                    style: TextStyle(
                      fontSize: 18.0, // Adjust the font size as needed
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts
                          .lato()
                          .fontFamily,
                    ),
                  ),
                ],
              ),
              Spacer(), // Push the following widget to the right
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                    baseCurrency, // Replace with your current currency
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Color(0xFFEEF4F8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: GoogleFonts
                            .lato()
                            .fontFamily,
                      ),
                      children: [
                        TextSpan(
                          text: DateFormat('MMMM yyyy').format(DateTime.now()),
                          style: GoogleFonts.montserrat(
                            fontSize: 30.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_outlined),
                        iconSize: 30,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NotificationsPage(
                                    username: widget.username,
                                  ),
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
              ),
              SizedBox(height: 24.0),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
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
                          Padding(
                            padding: const EdgeInsets.only(left: 5.0),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                cardColor: Colors.blueGrey,
                              ),
                              child: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert),
                                itemBuilder: (context) =>
                                [
                                  PopupMenuItem(
                                    value: 'currency',
                                    child: Text('Currency Converter'),
                                  ),
                                  PopupMenuItem(
                                    value: 'history',
                                    child: Text('Transaction History'),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'currency') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CurrencyConverterPage(
                                              username: widget.username,
                                              onCurrencyAdded: _currency,
                                            ),
                                      ),
                                    );
                                  } else if (value == 'history') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TransactionHistoryPage(
                                              username: widget.username,
                                            ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Additional content here
                  ],
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
                            icon: Icons.attach_money,
                            onIconPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      IncomePage(
                                          username: widget.username, onIncomeUpdated: _fetchIncome),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: HomePageCard(
                              title: 'Expense',
                              amount: totalExpenses.toStringAsFixed(2),
                              icon: Icons.wallet,
                              onIconPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ViewExpensesPage(
                                            username: widget.username),
                                  ),
                                );
                              }),
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
                            icon: Icons.calculate_outlined,
                            onIconPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ViewBudgetPage(username: widget.username),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: HomePageCard(
                            title: 'Invest',
                            amount: totalInvest.toStringAsFixed(2),
                            icon: Icons.auto_graph,
                            onIconPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ViewInvestPage(username: widget.username),
                                ),
                              );
                            },
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
          onTabTapped: (index) {
            setState(() {
              _bottomNavIndex = index;
            });
          },
        ).build(),
      ),
    );
  }
}