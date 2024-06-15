import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'event_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';
import 'add_calendar.dart';

class Calendar extends StatefulWidget {
  final String username;

  const Calendar({required this.username});

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late DateTime _selectedDay;
  Map<DateTime, List<String>> _notes = {};
  Map<String, List<Event>> _events = {};
  int _bottomNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _fetchEventsFromFirestore(DateTime.now());
  }

  //fetch calendar details from firebase
  Future<List<Event>> _fetchEventsFromFirestore(DateTime selectedDate) async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    //fetch from the event collection
    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('event')
          .where('event_date',
          isEqualTo: DateFormat('yyyy-MM-dd').format(selectedDate))
          .orderBy('id')
          .get();

      return eventSnapshot.docs.map((doc) => Event.fromDocument(doc)).toList();
    } else {
      return [];
    }
  }

  List<String> _getNotesForDay(DateTime day) {
    return _notes[day] ?? [];
  }

  //add new event to calendar
  void _addNoteToCalendar(Event event) async {
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
      });

      setState(() {
        String dateKey = DateFormat('yyyy-MM-dd').format(event.date);

        if (_events[dateKey] == null) {
          _events[dateKey] = [event];
        } else {
          _events[dateKey]!.add(event);
        }
      });
    }
  }

  //delete event from calendar
  void _deleteNoteFromCalendar(DateTime date, String note) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc('events')
        .collection('events')
        .where('date', isEqualTo: date)
        .where('note', isEqualTo: note)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    setState(() {
      _notes[date]?.remove(note);
      if (_notes[date]?.isEmpty ?? false) {
        _notes.remove(date);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFEEF4F8),
          title: Text('Calendar'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedDay = DateTime(
                        _selectedDay.year,
                        _selectedDay.month - 1,
                        _selectedDay.day,
                      );
                    });
                  },
                ),
                Text(
                  //display the month and year
                  '${DateFormat.yMMMM().format(_selectedDay)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      _selectedDay = DateTime(
                        _selectedDay.year,
                        _selectedDay.month + 1,
                        _selectedDay.day,
                      );
                    });
                  },
                ),
              ],
            ),
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
                _fetchEventsFromFirestore(selectedDay).then((events) {
                  setState(() {
                    _events[DateFormat('yyyy-MM-dd').format(selectedDay)] = events;
                  });
                });
              },

              eventLoader: _getNotesForDay,
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
                  onEventAdded: _addNoteToCalendar,
                  username: widget.username,
                  selectedDate: _selectedDay,
                ),
              ),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  //event list view
  Widget _buildEventList() {
    final notes = _getNotesForDay(_selectedDay);
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(notes[index]),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _deleteNoteFromCalendar(_selectedDay, notes[index]);
            },
          ),
        );
      },
    );
  }
}