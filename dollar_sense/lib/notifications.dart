import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

//page to display notifications
class NotificationsPage extends StatefulWidget {
  final String username;

  NotificationsPage({required this.username});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final navigationBarViewModel = NavigationBarViewModel();
  int _bottomNavIndex = 0;
  List<DocumentSnapshot> remindernotifications = [];
  List<DocumentSnapshot> budgetnotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    //fetch the available notifications
    fetchNotifications(widget.username);
  }

  Future<void> fetchNotifications(String username) async {
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('notifications')
          .get();

      List<DocumentSnapshot> fetchedNotifications = notificationsSnapshot.docs;

      List<DocumentSnapshot> reminderNotifications = fetchedNotifications
          .where((doc) => doc['type'] == 'Reminder')
          .toList();
      List<DocumentSnapshot> budgetNotifications = fetchedNotifications
          .where((doc) => doc['type'] == 'Budget')
          .toList();

      setState(() {
        remindernotifications = reminderNotifications;
        budgetnotifications = budgetNotifications;
        //update loading state
        _isLoading = false;
      });
    } else {
      setState(() {
        //update loading state if user is not found
        _isLoading = false;
      });
    }
  }

  //mark notification as read
  void _markAsRead(DocumentSnapshot notification) async {
    Map<String, dynamic> data = notification.data() as Map<String, dynamic>;

    String documentId = '${data['category']}_${data['month']}_${data['year']}';
    String userId = notification.reference.parent.parent!.id;

    //update both reminders if needed
    //when user marks as read, will update to true (will not send these notifications again)
    Map<String, dynamic> updates = {};
    if (data['read_first_reminder'] == false) {
      updates['read_first_reminder'] = true;
    }
    if (data['read_second_reminder'] == false) {
      updates['read_second_reminder'] = true;
    }

    if (updates.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('notifications')
          .doc(documentId)
          .update(updates);

      //fetch the notifications again to update the state
      await fetchNotifications(widget.username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text("Notifications"),
      ),
      body: Container(
        color: Color(0xFFEEF4F8),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : remindernotifications.isEmpty && budgetnotifications.isEmpty
            ? Center(
          child: Text(
            'No notifications available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (remindernotifications.isNotEmpty)
              Text("Reminder Notification"),
            Expanded(
                child: ListView.builder(
                  itemCount: remindernotifications.length,
                  itemBuilder: (context, index) {
                    var notification = remindernotifications[index];
                    var data = notification.data() as Map<String, dynamic>;

                    var eventDateTimestamp = data['event_date'];
                    String eventTitle = data['event_title'];
                    String reminder = data['reminder'];

                    //convert Timestamp to DateTime
                    DateTime eventDate;
                    if (eventDateTimestamp is DateTime) {
                      eventDate = eventDateTimestamp;
                    } else if (eventDateTimestamp is Timestamp) {
                      eventDate = eventDateTimestamp.toDate();
                    } else {
                      throw Exception("Invalid event_date format");
                    }

                    DateTime? reminderDate;
                    if (reminder == "1 day") {
                      reminderDate = eventDate.subtract(Duration(days: 1));
                    } else if (reminder == "3 days") {
                      reminderDate = eventDate.subtract(Duration(days: 3));
                    } else if (reminder == "1 week") {
                      reminderDate = eventDate.subtract(Duration(days: 7));
                    } else if (reminder == "2 weeks") {
                      reminderDate = eventDate.subtract(Duration(days: 14));
                    }

                    String eventDateStr = DateFormat('dd MMMM').format(eventDate);
                    String reminderDateStr = DateFormat('dd MMMM').format(reminderDate!);

                    //get the current date
                    DateTime currentDate = DateTime.now();

                    //check if the current date is between the reminder date and the event date
                    bool isBetween = currentDate.isAfter(reminderDate) && currentDate.isBefore(eventDate);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        color: isBetween ? Colors.red : Color(0xFFB3CDE4),
                        child: ListTile(
                          leading: Icon(
                            Icons.warning,
                            color: Colors.red,
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Event Date: $eventDateStr"),
                              Text("Title: $eventTitle"),
                              Text("Next Reminder: $reminderDateStr"),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () {
                              _markAsRead(notification);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ),
            if (budgetnotifications.isNotEmpty)
              Text("Budget Notification"),
              Expanded(
                child: ListView.builder(
                  itemCount: budgetnotifications.length,
                  itemBuilder: (context, index) {
                    var notification = budgetnotifications[index];
                    var data = notification.data() as Map<String, dynamic>;

                    //extracting relevant data
                    String budget_amount = data['budget_amount'].toString();
                    String category = data['category'];
                    String expense_amount = data['expense_amount'].toString();
                    int month = int.parse(data['month']);
                    int year = int.parse(data['year']);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        color: Color(0xFFB3CDE4),
                        child: ListTile(
                          leading: Icon(
                            Icons.warning,
                            color: Colors.red,
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Category: $category"),
                              Text("Month: $month"),
                              Text("Year: $year"),
                              Text("Budget: $budget_amount"),
                              Text("Expense Amount: $expense_amount"),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () {
                              _markAsRead(notification);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
          NavigationBarViewModel.onTabTapped(context, widget.username);
        },
      ).build(),
    );
  }
}
