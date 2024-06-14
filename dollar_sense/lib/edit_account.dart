import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_account.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class EditAccount extends StatefulWidget {
  final String username;

  EditAccount({required this.username});

  @override
  _EditAccountState createState() => _EditAccountState();
}

class _EditAccountState extends State<EditAccount> {
  final _formKey = GlobalKey<FormState>();
  String _fetchedEmail = ''; // Initialize with an empty string
  late String _username;
  String _password = '';
  String _confirmPassword = '';
  final navigationBarViewModel = NavigationBarViewModel();
  int _bottomNavIndex = 3;

  @override
  void initState() {
    super.initState();
    _fetchEmail();
  }

  //get the email to the username from database
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

  //update user password
  Future<void> _updateAccount() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_password != _confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password should be at least 6 characters long'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        String username = widget.username;
        User currentUser = FirebaseAuth.instance.currentUser!;

        //update password in database
        await currentUser.updatePassword(_password);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyAccount(username: widget.username),
          ),
        );
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Edit Account'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEEF4F8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: 2.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: 1.0,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: 2.0,
                  ),
                ),
                floatingLabelStyle: TextStyle(
                  color: Colors.black,
                ),
                labelStyle: TextStyle(
                  color: Colors.black,
                ),
                errorStyle: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
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
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'New Password',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _password = value;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _password) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _confirmPassword = value;
                    },
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: _updateAccount,
                    child: Text('Save'),
                  ),
                ],
              ),
            ),
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
