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

//page to view list of budgets and its notifications settings
class ViewBudgetPage extends StatefulWidget {
  final String username;

  const ViewBudgetPage({required this.username});

  @override
  _ViewBudgetPageState createState() => _ViewBudgetPageState();
}

class _ViewBudgetPageState extends State<ViewBudgetPage> {
  int currentIndex = 0;
  final navigationBarViewModel= NavigationBarViewModel();
  int _bottomNavIndex = 0; //navigation bar position index
  List<Budget> budgets = [];
  Map<String, bool> categoryNotifications = {};

  final viewModel = BudgetViewModel();
  final historyViewModel = TransactionHistoryViewModel();
  List<BudgetNotifications> budgetNotificationsList = []; //list for budget notifications
  //list for those category that have set notifications but does not have a budget yet
  List<String> categoriesWithNotificationsButNoBudget = [];

  @override
  void initState() {
    super.initState();

    categoriesWithNotificationsButNoBudget = [];

    //fetch and initialize budget and notifications data
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

      //populate categoryNotifications map
      setState(() {
        for (var notification in budgetNotificationsList) {
          categoryNotifications[notification.category] = true;
        }
      });

      //fetch categories with notifications but no budget
      var categoriesWithoutBudget = await _fetchCategoriesWithNotificationsButNoBudget();
      setState(() {
        categoriesWithNotificationsButNoBudget = categoriesWithoutBudget;
      });
    });
  }

  //fetch all the budgets
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

  //fetch all budget notifications
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


  //update changes for budget
  void _updateBudget(Budget editedBudget) {
    setState(() {
      int index = budgets.indexWhere((budget) => budget.id == editedBudget.id);
      if (index != -1) {
        budgets[index] = editedBudget;
      }
    });
  }

  //edit budget (direct to the Edit Budget Page)
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

  //get document ID for each budget
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

  //delete budget
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

        //remove from lists
        setState(() {
          budgets.removeWhere((element) => element.id == budget.id);
        });

        //add records to history collection in the database
        String specificText = "Delete Budget: ${budget.category} with ${budget.amount}";
        await historyViewModel.addHistory(specificText, widget.username, context);
      }
    }
  }

  //show delete confirmation
  Future<bool?> _showConfirmationDialog(BuildContext context, String action, dynamic item) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Confirm $action'),
          content: Text('Are you sure you want to $action this ${item.runtimeType.toString().toLowerCase()}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }


  //handle budgets that have newly added with notifications
  void handleBudgetNotificationsAdded(
      BudgetNotifications newBudgetNotifications) {
    print('New budget notifications added: $newBudgetNotifications');
  }

  //update changes for budget notifications
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

  //get the budget notifications document Id
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

  //delete budget notifications
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

  //refresh the page to get the latest changes
  void refreshData() async {
    for (var budget in budgets) {
      BudgetNotifications? notifications = await _fetchNotificationsForBudget(budget);
      if (notifications != null) {
        setState(() {
          //update the notifications for the given budget
          categoryNotifications[budget.category] = true;
        });
      } else {
        setState(() {
          //remove the notifications for the given budget if there are none
          categoryNotifications.remove(budget.category);
        });
      }
    }
  }

  //fetch categories that have notifications but without a budget created
  Future<List<String>> _fetchCategoriesWithNotificationsButNoBudget() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;

      //fetch budget categories
      QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budget')
          .get();

      Set<String> budgetCategories = budgetSnapshot.docs
          .map((doc) => doc['budget_category'] as String)
          .toSet();

      //fetch budget notification categories
      QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budgetNotifications')
          .get();

      Set<String> notificationCategories = notificationsSnapshot.docs
          .where((doc) => doc['budgetNotifications_category'] != null)
          .map((doc) => doc['budgetNotifications_category'] as String)
          .toSet();

      //categories that have notifications but no budget
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
                      //if no budget found
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
                              //display the list of budget categories
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
          ],
        ),
      ),
      //navigation bar
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped: NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }

  //helper method to build the category list for expenses
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
              //show the total amount spent by each expense category
                'Total Amount: ${totalAmount?.toStringAsFixed(2) ?? 'N/A'}'),
          ),
        );
      },
    );
  }

  //listview building for budget
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
                  //show the amount planned to achieve
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
            //display the text for those categories that have notifications but without a budget
            'Categories with notifications but no budget: ${categoriesWithNotificationsButNoBudget.join(', ')}',
            style: TextStyle(fontSize: 16, color: Color(0xffd3746c)),
          ),
        ),
      ],
    );
  }

  //onTap to edit or delete the budget notifications for the specific budget category
  void _handleBudgetCategoryTap(BuildContext context, Budget budget) async {
    BudgetNotifications? budgetNotifications = await _fetchNotificationsForBudget(budget);
    if (budgetNotifications != null) {
      String documentId = await _getNotificationsDocumentId(budgetNotifications);

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
                    //navigate to modify notifications page
                    _navigateToModifyNotificationsPage(context, budgetNotifications, documentId);
                  },
                ),
                ListTile(
                  title: Text('Delete Notifications'),
                  onTap: () {
                    //delete notifications
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

  //edit budget notifications (page direct)
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

  //delete notifications
  void _deleteNotifications(BudgetNotifications budgetNotifications) {
   _deleteBudgetNotifications(budgetNotifications);
  }
}