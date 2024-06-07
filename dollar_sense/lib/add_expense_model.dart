import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  String title;
  double amount;
  String category;
  String paymentMethod;
  String description;
  String date;
  String time;
  File? receiptImage;
  String imageBase64;

  Expense({
    required this.id,
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
      id: doc['id'],
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


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'payment_method': paymentMethod,
      'description': description,
      'date': date,
      'time': time,
      'receipt_image': receiptImage?.path ?? '',
      'receipt_image_base64': imageBase64 ?? '',
    };
  }
}


