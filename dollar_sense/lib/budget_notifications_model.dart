import 'package:cloud_firestore/cloud_firestore.dart';

//budget notifications class
class BudgetNotifications{
  final String id;
  String category;
  String reminderType;
  String firstReminder;
  String secondReminder;

  BudgetNotifications({
    required this.id,
    required this.category,
    required this.reminderType,
    required this.firstReminder,
    required this.secondReminder,

  });

  factory BudgetNotifications.fromDocument(DocumentSnapshot doc) {
    return BudgetNotifications(
      id: doc['budgetNotifications_id'],
      category: doc['budgetNotifications_category'],
      reminderType: doc['budgetNotifications_reminder_type'],
      firstReminder: doc['budgetNotifications_first_reminder'],
      secondReminder: doc['budgetNotifications_second_reminder'],
    );
  }

  //map changes
  Map<String, dynamic> toMap() {
    return {
      'budgetNotifications_id': id,
      'budgetNotifications_category': category,
      'budgetNotifications_reminder_type': reminderType,
      'budgetNotifications_first_reminder': firstReminder,
      'budgetNotifications_second_reminder': secondReminder,
    };
  }

}