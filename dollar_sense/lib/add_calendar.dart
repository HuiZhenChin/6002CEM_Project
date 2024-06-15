import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'event_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class AddCalendarPage extends StatefulWidget {
  final String username;
  final Function(Event) onEventAdded;
  final DateTime selectedDate;

  const AddCalendarPage({
    required this.username,
    required this.onEventAdded,
    required this.selectedDate,
  });

  @override
  _AddCalendarPageState createState() => _AddCalendarPageState();
}

class _AddCalendarPageState extends State<AddCalendarPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _eventController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedReminder = '1 day';
  String _customReminder = '3 days';
  int _bottomNavIndex = 1;

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  //add new event to the calendar
  Future<void> addEvent(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      String title = _eventController.text;
      DateTime date = DateTime(
          widget.selectedDate.year, widget.selectedDate.month,
          widget.selectedDate.day);
      String reminder = _selectedReminder == '1 day'
          ? '1 day'
          : _customReminder;

      DocumentReference counterDoc = _firestore.collection('counters').doc(
          'eventCounter');
      DocumentSnapshot counterSnapshot = await counterDoc.get();

      int newEventId = 1;
      if (counterSnapshot.exists) {
        newEventId = counterSnapshot['currentId'] as int;
        newEventId++;
      }

      await counterDoc.set({'currentId': newEventId});

      Event newEvent = Event(
        id: newEventId.toString(),
        title: title,
        date: date,
        reminder: reminder,
      );

      //wait when saving to database
      await _saveEventToFirestore(newEvent, widget.username, context);

      _eventController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event added to calendar')),
      );
      Navigator.pop(context);
    }
  }

  //save to Database
  Future<void> _saveEventToFirestore(Event event, String username,
      BuildContext context) async {
    QuerySnapshot userSnapshot = await _firestore
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      CollectionReference eventCollection = _firestore
          .collection('dollar_sense')
          .doc(userId)
          .collection('notifications');

      //save the event with the details
      Map<String, dynamic> eventData = {
        'event_id': event.id,
        'event_title': event.title,
        'event_date': event.date,
        'reminder': event.reminder,
        'type': "Reminder", // Add reminder to Firestore
      };

      await eventCollection.add(eventData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String givenDate = '${widget.selectedDate.year}-${widget.selectedDate
        .month}-${widget.selectedDate.day}';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Add Calendar Event'),
      ),
      body: Container(
        color: Color(0xFFEEF4F8),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery
                  .of(context)
                  .size
                  .height,
            ),
            child: IntrinsicHeight(
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
                      Text(
                        givenDate,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      Text('Reminder:'),
                      DropdownButton<String>(
                        value: _selectedReminder,
                        items: <String>['1 day', 'Custom']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedReminder = value!;
                          });
                        },
                      ),
                      if (_selectedReminder == 'Custom') ...[
                        SizedBox(height: 10),
                        DropdownButton<String>(
                          value: _customReminder,
                          items: <String>['3 days', '1 week', '2 weeks']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _customReminder = value!;
                            });
                          },
                        ),
                      ],
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => addEvent(context),
                        child: Text('Add Event'),
                      ),
                      Expanded(child: Container()),
                      // Ensure the container expands to fill remaining space
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped:
        NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }
}
