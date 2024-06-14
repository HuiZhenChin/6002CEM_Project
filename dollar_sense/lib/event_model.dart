import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  String title;
  DateTime date;
  final String reminder;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.reminder,
  });

  factory Event.fromDocument(DocumentSnapshot doc) {
    return Event(
      id: doc['event_id'],
      title: doc['event_title'],
      date: doc['event_date'],
      reminder: doc['reminder'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event_id': id,
      'event_title': title,
      'event_date': date,

    };
  }

}