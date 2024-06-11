import 'package:cloud_firestore/cloud_firestore.dart';

class Calendar {
  final String id;
  String category;
  String month;
  String year;

  Calendar({
    required this.id,
    required this.category,
    required this.month,
    required this.year,

  });

  factory Calendar.fromDocument(DocumentSnapshot doc) {
    return Calendar(
      id: doc['calendar_id'],
      category: doc['calendar_category'],
      month: doc['calendar_month'],
      year: doc['calendar_year'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calendar_id': id,
      'calendar_category': category,
      'calendar_month': month,
      'calendar_year': year,
    };
  }

}