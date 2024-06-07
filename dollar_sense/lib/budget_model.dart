import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  String category;
  double amount;


  Budget({
    required this.category,
    required this.amount,

  });

  factory Budget.fromDocument(DocumentSnapshot doc) {
    return Budget(
      category: doc['budget_category'],
      amount: doc['budget_amount'],

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'budget_category': category,
      'budget_amount': amount,
    };
  }

}