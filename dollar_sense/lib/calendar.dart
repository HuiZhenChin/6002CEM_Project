import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'add_calendar.dart';
import 'event_model.dart';

class Calendar extends StatefulWidget {
  final String username;

  const Calendar({required this.username});

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
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
          _events.clear(); //clear existing events before adding new ones

          for (var doc in eventSnapshot.docs) {
            Timestamp eventTimestamp = doc["event_date"];
            String eventId = doc["event_id"];
            String eventTitle = doc["event_title"];

            //convert the Timestamp to a DateTime object
            DateTime eventDate = eventTimestamp.toDate();
            DateTime normalizedDate = _normalizeDate(eventDate);

            // Initialize the list if it doesn't exist
            if (_events[normalizedDate] == null) {
              _events[normalizedDate] = [];
            }

            //add the event to the list
            _events[normalizedDate]!.add(Event(
              id: eventId,
              title: eventTitle,
              date: eventDate,
              reminder: '1 day', //replace with your actual reminder logic
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

  //add to list
  void _addEventToState(Event event) {
    setState(() {
      DateTime normalizedDate = _normalizeDate(event.date);
      if (_events[normalizedDate] == null) {
        _events[normalizedDate] = [];
      }
      _events[normalizedDate]!.add(event);
    });
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

  void _onPreviousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
  }

  void _onNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Calendar'),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: _onPreviousMonth,
                  ),
                  Text(
                    DateFormat.yMMMM().format(_focusedDay),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: _onNextMonth,
                  ),
                ],
              ),
            ),
            TableCalendar(
              firstDay: DateTime.utc(2021, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              headerVisible: false,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCalendarPage(
                onEventAdded: _addEventToState,
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
