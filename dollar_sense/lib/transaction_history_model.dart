import 'package:cloud_firestore/cloud_firestore.dart';

class History {
  String text;
  String date;


  History({
    required this.text,
    required this.date,

  });

  factory History.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return History(
      date: data['history_date'] ?? '',
      text: data['history_text'] ?? '',
    );
  }

}