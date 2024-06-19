import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'event_model.dart';

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

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  //add new event to the calendar
  Future<void> addEvent(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      String title = _eventController.text;
      DateTime date = DateTime(widget.selectedDate.year,
          widget.selectedDate.month, widget.selectedDate.day);
      String reminder =
          _selectedReminder == '1 day' ? '1 day' : _customReminder;

      DocumentReference counterDoc =
          _firestore.collection('counters').doc('eventCounter');
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
      widget.onEventAdded(newEvent);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event added to calendar')),
      );
      Navigator.pop(context);
    }
  }

  //save to Database
  Future<void> _saveEventToFirestore(
      Event event, String username, BuildContext context) async {
    QuerySnapshot userSnapshot = await _firestore
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      CollectionReference notificationsCollection = _firestore
          .collection('dollar_sense')
          .doc(userId)
          .collection('notifications');

      CollectionReference eventsCollection = _firestore
          .collection('dollar_sense')
          .doc(userId)
          .collection('event');

      //save the event with the details to the notifications collection
      Map<String, dynamic> eventData = {
        'event_id': event.id,
        'event_title': event.title,
        'event_date': event.date,
        'reminder': event.reminder,
        'type': "Reminder", //add reminder to Firestore
      };

      //save to notifications collection
      await notificationsCollection.add(eventData);

      //save to event collection
      await eventsCollection.add({
        'event_id': event.id,
        'event_title': event.title,
        'event_date': event.date,
        'reminder': event.reminder,

      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event added to calendar')),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not found')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    String givenDate =
        '${widget.selectedDate.year}-${widget.selectedDate.month}-${widget.selectedDate.day}';
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
                Text(
                  givenDate,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text('Reminder:'),
                DropdownButton<String>(
                  value: _selectedReminder,
                  items: <String>['1 day', 'Custom'].map((String value) {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: Size(double.infinity, 60),
                  ),
                  onPressed: () => addEvent(context),
                  child: Text(
                    'Add Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
