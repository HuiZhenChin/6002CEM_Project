import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/calendar_model.dart';
import 'package:flutter/material.dart';
import 'calendar_notifications_model.dart';
import 'calendar_notifications_view_model.dart';
import 'add_calendar_custom_input_view.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class CalendarNotificationsPage extends StatefulWidget {
  final String username;
  final Function(CalendarNotifications) onCalendarNotificationsAdded;

  const CalendarNotificationsPage({required this.username, required this.onCalendarNotificationsAdded});

  @override
  _CalendarNotificationsPageState createState() => _CalendarNotificationsPageState();
}

class _CalendarNotificationsPageState extends State<CalendarNotificationsPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedReminderType = 'Custom';
  double _firstReminderAmount = 10;
  String _secondReminderOption = 'None';
  List<String> _budgetCategories = [];
  bool _isLoading = true;
  final List<String> _reminderTypes = ['Custom', 'Basic'];
  final List<String> _secondReminderOptions = ['None', 'Budget Exceeded'];
  String selectedCategory = "";
  final viewModel = CalendarNotificationsViewModel();
  final navigationBarViewModel= NavigationBarViewModel();
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();

  }

  String? _validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName cannot be empty';
    }

    return null;
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
                        viewModel.reminderTypeController.text = "Basic";
                        viewModel.firstReminderController.text = "10%";
                        viewModel.secondReminderController.text = 'Budget Exceeded';
                      } else {
                        // Update text fields for Custom reminder type
                        viewModel.reminderTypeController.text = "Custom";
                        viewModel.firstReminderController.text = "";
                        viewModel.secondReminderController.text = '';
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
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select 1st Reminder (Remaining Budget) %'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 9,
              itemBuilder: (context, index) {
                final percentage = (index + 1) * 10.0;
                return ListTile(
                  title: Text('$percentage'),
                  onTap: () {
                    setState(() {
                      _firstReminderAmount = percentage;
                      viewModel.firstReminderController.text = '$percentage%';
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

  void _showSecondReminderDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                      _secondReminderOption = _secondReminderOptions[index];
                      viewModel.secondReminderController.text = _secondReminderOption;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFAE5CC),
        title: Text('Budget Notifications'),
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
                      CustomInputField(
                        controller: viewModel.reminderTypeController,
                        labelText: 'Reminder Type',
                        inputFormatters: [],
                        onTap: () => _showReminderTypeDialog(),
                        validator: (value) => _validateField(value, 'Reminder Type'),
                      ),
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: viewModel.firstReminderController,
                        labelText: '1st Reminder',
                        inputFormatters: [],
                        onTap: _selectedReminderType == 'Basic' ? null : _showFirstReminderDialog,
                        readOnly: _selectedReminderType == 'Basic',
                        validator: (value) => _validateField(value, '1st Reminder'),
                      ),
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: viewModel.secondReminderController,
                        labelText: '2nd Reminder',
                        inputFormatters: [],
                        onTap: _selectedReminderType == 'Basic' ? null : _showSecondReminderDialog,
                        readOnly: _selectedReminderType == 'Basic',
                        validator: (value) => _validateField(value, '2nd Reminder'),
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
                                  color: Color(0xFF52444E),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
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
                                  color: Color(0xFF332B28),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      viewModel.addCalendarNotifications(
                                          widget.onCalendarNotificationsAdded,
                                          widget.username, context);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Calendar Notifications Added')),
                                      );
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'SAVE',
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
