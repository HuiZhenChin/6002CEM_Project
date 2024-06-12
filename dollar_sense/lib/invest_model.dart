import 'package:cloud_firestore/cloud_firestore.dart';

//invest class
class Invest {
  final String id;
  String title;
  double amount;
  String date;


  Invest({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,

  });

  //map the Firestore document fields to Invest attributes
  factory Invest.fromDocument(DocumentSnapshot doc) {
    return Invest(
      id: doc['id'],
      title: doc['invest_title'],
      amount: doc['invest_amount'],
      date: doc['invest_date'],

    );
  }

  //map changes
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invest_title': title,
      'invest_amount': amount,
      'invest_date': date,
    };
  }

}
