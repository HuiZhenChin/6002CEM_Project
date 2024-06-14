import 'package:dollar_sense/calendar.dart';
import 'package:dollar_sense/report.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'my_account.dart';

//navigation bar view model (page direct)
class NavigationBarViewModel {
  static Function(int) onTabTapped(BuildContext context, String username) {
    return (int index) {
      if (index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(username: username),
          ),
        );
        
      } else if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Calendar(username: username,),
          ),
        );
      } else if (index == 2) {Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GraphPage(username: username),
        ),
      );}else if (index == 3) {
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
