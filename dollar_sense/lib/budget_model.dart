import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  String category;
  double amount;
  String month;
  String year;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,

  });

  factory Budget.fromDocument(DocumentSnapshot doc) {
    return Budget(
      id: doc['budget_id'],
      category: doc['budget_category'],
      amount: doc['budget_amount'],
      month: doc['budget_month'],
      year: doc['budget_year'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'budget_id': id,
      'budget_category': category,
      'budget_amount': amount,
      'budget_month': month,
      'budget_year': year,
    };
  }

}