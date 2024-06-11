import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Calendar extends StatelessWidget {
  final String id;
  final int month;
  final int year;

  Calendar({required this.id, required this.month, required this.year});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
      ),
      body: Center(
        child: Text('Calendar ID: $id, Month: $month, Year: $year'),
      ),
    );
  }
}

class CalendarScreen extends StatelessWidget {
  final String username;

  CalendarScreen({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(username)
            .collection('events')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var events = snapshot.data!.docs;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              var event = events[index];
              return ListTile(
                title: Text(event['title']),
                subtitle: Text(event['description']),
              );
            },
          );
        },
      ),
    );
  }
}
