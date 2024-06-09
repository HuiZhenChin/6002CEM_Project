import 'package:dollar_sense/notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'my_account.dart';


class NavigationBarViewModel {
  static Function(int) onTabTapped(BuildContext context, String username) {
    return (int index) {
      if (index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyApp(username: username),
          ),
        );
        
      } else if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationsPage(username: username),
          ),
        );
      }else if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyAccount(username: username),
          ),
        );
      }
    };
  }
}
