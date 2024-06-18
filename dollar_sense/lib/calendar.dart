import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'add_calendar.dart'; // Assuming this is where you define AddCalendarPage
import 'event_model.dart'; // Assuming this is where you define the Event class

class Calendar extends StatefulWidget {
  final String username;

  const Calendar({required this.username});

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late DateTime _selectedDay;
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initializeEvents();
  }

  Future<void> _initializeEvents() async {
    try {
      String username = widget.username;
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('event')
            .get();

        setState(() {
          _events.clear(); // Clear existing events before adding new ones

          for (var doc in eventSnapshot.docs) {
            Timestamp eventTimestamp = doc["event_date"];
            String eventId = doc["event_id"];
            String eventTitle = doc["event_title"];

            // Convert the Timestamp to a DateTime object
            DateTime eventDate = eventTimestamp.toDate();
            DateTime normalizedDate = _normalizeDate(eventDate);

            // Initialize the list if it doesn't exist
            if (_events[normalizedDate] == null) {
              _events[normalizedDate] = [];
            }

            // Add the event to the list
            _events[normalizedDate]!.add(Event(
              id: eventId,
              title: eventTitle,
              date: eventDate,
              reminder: '1 day', // Replace with your actual reminder logic
            ));

            print(_events);
          }
        });
      }
    } catch (e) {
      print("Error initializing events: $e");
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _addEventToFirestore(Event event) async {
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
            .collection('event')
            .add({
          'event_date': event.date,
          'event_title': event.title,
          'reminder': event.reminder,
        });

        setState(() {
          DateTime normalizedDate = _normalizeDate(event.date);
          if (_events[normalizedDate] == null) {
            _events[normalizedDate] = [event];
          } else {
            _events[normalizedDate]!.add(event);
          }
        });
      }
    } catch (e) {
      print("Error adding event to Firestore: $e");
    }
  }

  void _deleteEventFromFirestore(Event event) async {
    try {
      String username = widget.username;
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('event')
            .where('event_id', isEqualTo: event.id)
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        setState(() {
          DateTime normalizedDate = _normalizeDate(event.date);
          _events[normalizedDate]?.remove(event);
          if (_events[normalizedDate]?.isEmpty ?? false) {
            _events.remove(normalizedDate);
          }
        });
      }
    } catch (e) {
      print("Error deleting event from Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2021, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            headerVisible: false,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCalendarPage(
                onEventAdded: _addEventToFirestore,
                username: widget.username,
                selectedDate: _selectedDay,
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay);
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(events[index].title),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _deleteEventFromFirestore(events[index]);
            },
          ),
        );
      },
    );
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }
}
