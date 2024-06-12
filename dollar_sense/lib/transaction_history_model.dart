import 'package:cloud_firestore/cloud_firestore.dart';

//history class
class History {
  String text;
  String date;


  History({
    required this.text,
    required this.date,

  });

  //map the Firestore document fields to History attributes
  factory History.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return History(
      date: data['history_date'] ?? '',
      text: data['history_text'] ?? '',
    );
  }

}