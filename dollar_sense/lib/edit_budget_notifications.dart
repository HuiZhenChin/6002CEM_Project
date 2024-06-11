import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/budget_notifications.dart';
import 'package:dollar_sense/budget_notifications_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'budget_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';
import 'transaction_history_view_model.dart';
import 'add_expense_custom_input_view.dart';
import 'currency_input_formatter.dart';

class EditBudgetNotifications extends StatefulWidget {
  final Function(BudgetNotifications) onBudgetNotificationsUpdated;
  final String username;
  final BudgetNotifications budgetNotifications;
  final String documentId;

  const EditBudgetNotifications({
    required this.onBudgetNotificationsUpdated,
    required this.username,
    required this.budgetNotifications,
    required this.documentId,
  });

  @override
  _EditBudgetNotificationsState createState() => _EditBudgetNotificationsState();
}

class _EditBudgetNotificationsState extends State<EditBudgetNotifications> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  final navigationBarViewModel= NavigationBarViewModel();
  int _bottomNavIndex = 0;

  late TextEditingController notificationCategoryController;
  late TextEditingController reminderTypeController;
  late TextEditingController firstReminderController;
  late TextEditingController secondReminderController;

  late String originalReminderType;
  late String originalFirstReminder;
  late String originalSecondReminder;

  String _selectedReminderType = 'Basic';
  final List<String> _reminderTypes = ['Custom', 'Basic'];
  final List<String> _firstReminderOptions = ['10', '20' , '30' , '40' , '50' , '60' , '70' , '80' , '90' ,];
  final List<String> _secondReminderOptions = ['None', 'Budget Exceeded'];

  @override
  void initState() {
    super.initState();

    reminderTypeController = TextEditingController(text: widget.budgetNotifications.reminderType);
    firstReminderController = TextEditingController(text: widget.budgetNotifications.firstReminder);
    secondReminderController = TextEditingController(text: widget.budgetNotifications.secondReminder);

    originalReminderType= widget.budgetNotifications.reminderType;
    originalFirstReminder= widget.budgetNotifications.firstReminder;
    originalSecondReminder= widget.budgetNotifications.secondReminder;

  }

  @override
  void dispose() {
    notificationCategoryController.dispose();
    reminderTypeController.dispose();
    firstReminderController.dispose();
    secondReminderController.dispose();
    super.dispose();
  }

  void _saveBudgetNotifications() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      BudgetNotifications updatedBudgetNotifications = BudgetNotifications(
        id: widget.budgetNotifications.id,
        category: widget.budgetNotifications.category,
        reminderType: reminderTypeController.text,
        firstReminder: firstReminderController.text,
        secondReminder: secondReminderController.text,
      );

      try {
        String username = widget.username;
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
              .doc(widget.documentId)
              .update(updatedBudgetNotifications.toMap());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget notifications updated'),
          ),
        );

        widget.onBudgetNotificationsUpdated(updatedBudgetNotifications);

        setState(() {
          _isSaving = false;
        });
      } catch (error) {
        print('Error updating budget notifications: $error');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update budget notifications'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    // Set controllers' text back to original values
    reminderTypeController.text= originalReminderType;
    firstReminderController.text= originalFirstReminder;
    secondReminderController.text= originalSecondReminder;

    setState(() {
      _isSaving = false;
    });
  }

// Fetch Budget Notifications Data
  Future<List<BudgetNotifications>> _fetchBudgetNotifications() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot budgetNotificationsSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budgetNotifications')
          .where('budgetNotifications_category', isEqualTo: widget.budgetNotifications.category)
          .get();

      return budgetNotificationsSnapshot.docs
          .map((doc) => BudgetNotifications.fromDocument(doc))
          .toList();
    } else {
      return [];
    }

  }

  Future<void> _showReminderTypeDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Reminder Type'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _reminderTypes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_reminderTypes[index]),
                  onTap: () {
                    setState(() {
                      _selectedReminderType = _reminderTypes[index];
                      if (_selectedReminderType == 'Basic') {
                        // Update text fields for Basic reminder type
                        reminderTypeController.text = "Basic";
                        firstReminderController.text = "10 (Remaining Budget) %";
                        secondReminderController.text = 'Budget Exceeded';
                      } else {
                        // Update text fields for Custom reminder type
                        reminderTypeController.text = "Custom";
                        firstReminderController.text = '';
                        secondReminderController.text = '';
                      }
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }


  void _showFirstReminderDialog() async {
    String originalSecondReminder = firstReminderController.text;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Select 1st Reminder (Remaining Budget) %'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _firstReminderOptions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_firstReminderOptions[index]),
                  onTap: () {
                    setState(() {
                      firstReminderController.text = _firstReminderOptions[index];
                    });
                    Navigator.of(context).pop();
                  },
                  // Highlight the item if it matches the original value
                  selected: _firstReminderOptions[index] == originalFirstReminder,
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSecondReminderDialog() async {
    String originalSecondReminder = secondReminderController.text;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Select 2nd Reminder'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _secondReminderOptions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_secondReminderOptions[index]),
                  onTap: () {
                    setState(() {
                      secondReminderController.text = _secondReminderOptions[index];
                    });
                    Navigator.of(context).pop();
                  },
                  // Highlight the item if it matches the original value
                  selected: _secondReminderOptions[index] == originalSecondReminder,
                );
              },
            ),
          ),
        );
      },
    );
  }

  String? _validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName cannot be empty';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Edit Budget Notifications'),
      ),
      body: Container(
        decoration: BoxDecoration(
         color: Color(0xFFEEF4F8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 10),
                      FutureBuilder<List<BudgetNotifications>>(
                        future: _fetchBudgetNotifications(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text('No budget notifications found.'),
                            );
                          } else {
                            return Column(
                              children: [
                                Text(
                                  'Budget Notifications',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                CustomInputField(
                                  controller: reminderTypeController,
                                  labelText: 'Reminder Type',
                                  inputFormatters: [],
                                  onTap: () => _showReminderTypeDialog(),
                                  validator: (value) => _validateField(value, 'Reminder Type'),
                                ),
                                SizedBox(height: 10),
                                CustomInputField(
                                  controller: firstReminderController,
                                  labelText: '1st Reminder (% remaining)',
                                  inputFormatters: [],
                                  onTap: _selectedReminderType == 'Basic' ? null : () => _showFirstReminderDialog(),
                                  readOnly: _selectedReminderType == 'Basic',
                                  validator: (value) => _validateField(value, '1st Reminder'),
                                ),

                                SizedBox(height: 10),
                                CustomInputField(
                                  controller: secondReminderController,
                                  labelText: '2nd Reminder',
                                  inputFormatters: [],
                                  onTap: _selectedReminderType == 'Basic' ? null : () => _showSecondReminderDialog(),
                                  readOnly: _selectedReminderType == 'Basic',
                                  validator: (value) => _validateField(value, '2nd Reminder'),
                                ),

                                SizedBox(height: 20),
                              ],
                            );
                          }
                        }, // Remove extra parentheses here
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Color(0xFF85A5C3),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _cancelEdit();
                                    Navigator.pop(
                                        context); // Dismiss the EditBudget screen
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'CANCEL',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Color(0xFF547FA3),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveBudgetNotifications,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                  ),
                                  child: _isSaving
                                      ? CircularProgressIndicator()
                                      : Text(
                                    'UPDATE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    );
  }
}

