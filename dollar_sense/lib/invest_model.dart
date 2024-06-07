import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Invest.fromDocument(DocumentSnapshot doc) {
    return Invest(
      id: doc['id'],
      title: doc['invest_title'],
      amount: doc['invest_amount'],
      date: doc['invest_date'],

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invest_title': title,
      'invest_amount': amount,
      'invest_date': date,
    };
  }

}
