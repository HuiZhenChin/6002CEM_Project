import 'dart:io';

class Expense {
  final String title;
  final double amount;
  final String category;
  final String paymentMethod;
  final String description;
  final String date;
  final String time;
  final File? receiptImage;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.description,
    required this.date,
    required this.time,
    this.receiptImage,
  });
}

