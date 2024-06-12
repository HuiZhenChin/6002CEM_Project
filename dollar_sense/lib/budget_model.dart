import 'package:cloud_firestore/cloud_firestore.dart';

//budget class
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

  //map the Firestore document fields to Budget attributes
  factory Budget.fromDocument(DocumentSnapshot doc) {
    return Budget(
      id: doc['budget_id'],
      category: doc['budget_category'],
      amount: doc['budget_amount'],
      month: doc['budget_month'],
      year: doc['budget_year'],
    );
  }

  //map changes to database
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