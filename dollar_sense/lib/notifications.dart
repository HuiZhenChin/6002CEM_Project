import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'budget_model.dart';
import 'budget_notifications.dart';
import 'add_expense_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';
import 'budget_notifications_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class NotificationsPage extends StatefulWidget {
  final String username;

  NotificationsPage({required this.username});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final navigationBarViewModel = NavigationBarViewModel();
  int _bottomNavIndex = 0;
  List<DocumentSnapshot> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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

      List<DocumentSnapshot> fetchedNotifications = [];

      for (var doc in notificationsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('category') &&
            data.containsKey('month') &&
            data.containsKey('year') &&
            data.containsKey('read_first_reminder') ||
            data.containsKey('read_second_reminder')) {
          // Add the document if it has any of the reminders set to false
          if (data['read_first_reminder'] == false ||
              data['read_second_reminder'] == false) {
            fetchedNotifications.add(doc);
          }
        }
      }

      setState(() {
        notifications = fetchedNotifications;
        _isLoading = false;  // Update loading state
      });
    } else {
      setState(() {
        _isLoading = false;  // Update loading state if user is not found
      });
    }
  }


  void _markAsRead(DocumentSnapshot notification) async {
    Map<String, dynamic> data = notification.data() as Map<String, dynamic>;

    String documentId = '${data['category']}_${data['month']}_${data['year']}';
    String userId = notification.reference.parent.parent!.id;

    // Update both reminders if needed
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

      // Fetch the notifications again to update the state
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
            : notifications.isEmpty
            ? Center(child: Text(
          'No notifications available',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),)
            : ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            var notification = notifications[index];
            var data = notification.data() as Map<String, dynamic>;
            String message = '';

            if (data['read_first_reminder'] == false) {
              message +=
              "${data['category']} : Alert: ${data['budgetNotifications_first_reminder']}% remaining!\n";
            }
            if (data['read_second_reminder'] == false) {
              message += "${data['category']}: Budget Exceeded!";
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical spacing between rows
              child: Container(
                color: Color(0xFFB3CDE4), // Background color for each list item
                child: ListTile(
                  leading: Icon(
                    Icons.warning, // Alert icon
                    color: Colors.red,
                  ),
                  title: Text(message.trim()),
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
