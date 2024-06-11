import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarNotifications{
  final String id;
  String reminderType;
  String firstReminder;
  String secondReminder;

  CalendarNotifications({
    required this.id,
    required this.reminderType,
    required this.firstReminder,
    required this.secondReminder,

  });

  factory CalendarNotifications.fromDocument(DocumentSnapshot doc) {
    return CalendarNotifications(
      id: doc['calendarNotifications_id'],
      reminderType: doc['calendarNotifications_reminder_type'],
      firstReminder: doc['calendarNotifications_first_reminder'],
      secondReminder: doc['calendarNotifications_second_reminder'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'budgetNotifications_id': id,
      'budgetNotifications_reminder_type': reminderType,
      'budgetNotifications_first_reminder': firstReminder,
      'budgetNotifications_second_reminder': secondReminder,
    };
  }

}