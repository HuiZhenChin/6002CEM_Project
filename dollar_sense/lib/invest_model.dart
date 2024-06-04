import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class Invest {
  final String title;
  final double amount;
  final String date;


  Invest({
    required this.title,
    required this.amount,
    required this.date,

  });

}
