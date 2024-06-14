import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_account.dart';
import 'login_main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class MyAccount extends StatefulWidget {
  final String username;

  MyAccount({required this.username});

  @override
  _MyAccountState createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  final TextEditingController _emailController = TextEditingController();
  String _fetchedEmail = '';
  String _username = '';
  String _email = '';
  final navigationBarViewModel = NavigationBarViewModel();
  int _bottomNavIndex = 3;

  @override
  void initState() {
    super.initState();
    _fetchEmail();
  }

  //fetch email of the user
  Future<void> _fetchEmail() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        String email = userDoc['email'] ?? '';
        setState(() {
          _fetchedEmail = email;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('My Account'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEEF4F8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Username: ${widget.username}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Email: $_fetchedEmail',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EditAccount(username: widget.username)),
                  );
                },
                child: Text('Edit Account'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MyLogin()),
                  );
                },
                child: Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped: NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }
}
