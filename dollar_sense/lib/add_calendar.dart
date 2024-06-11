import 'package:flutter/material.dart';

import 'CalendarNotificationsViewModel.dart';

class AddCalendarPage extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime, String) onEventAdded;

  const AddCalendarPage({
    required this.selectedDate,
    required this.onEventAdded,
  });

  @override
  _AddCalendarPageState createState() => _AddCalendarPageState();
}

class _AddCalendarPageState extends State<AddCalendarPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventController = TextEditingController();
  String _selectedReminderType = 'Custom';
  double _firstReminderAmount = 10;
  String _secondReminderOption = 'None';
  final List<String> _reminderTypes = ['Custom', 'Basic'];
  final List<String> _secondReminderOptions = ['None', 'Payment Overdued'];
  String selectedCategory = "";
  final viewModel = CalendarNotificationsViewModel();
  int _bottomNavIndex = 0;

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
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
                        viewModel.firstReminderController.text = "Bill Payment Overdueing in 3 days!";
                        viewModel.secondReminderController.text = 'Bill Payment Overdued!';
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
        title: Text('Add Calendar Event'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _eventController,
                  decoration: InputDecoration(labelText: 'Event Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter event name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Text('Selected Date:'),
                SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Icon(Icons.calendar_today),
                    SizedBox(width: 10),
                    Text(
                      '${widget.selectedDate.year}-${widget.selectedDate.month}-${widget.selectedDate.day}',
                    ),
                  ],
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
                                  SnackBar(content: Text('Budget Notifications Added')),
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








                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Call the callback to add the event to the calendar
                      widget.onEventAdded(widget.selectedDate, _eventController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Event added to calendar')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add Event'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
