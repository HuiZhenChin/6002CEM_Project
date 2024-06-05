import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Expense {
  final String title;
  final double amount;
  final String category;
  final String paymentMethod;
  final String description;
  final String date;
  final String time;
  final File? receiptImage;
  final String imageBase64;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.description,
    required this.date,
    required this.time,
    this.receiptImage,
    required this.imageBase64

  });

  factory Expense.fromDocument(DocumentSnapshot doc) {
    return Expense(
      title: doc['title'],
      amount: doc['amount'],
      category: doc['category'],
      paymentMethod: doc['payment_method'],
      description: doc['description'],
      date: doc['date'],
      time: doc['time'],
      imageBase64: doc['receipt_image_base64'],
    );
  }
}


