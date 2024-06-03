import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/edit_account.dart';
import 'package:dollar_sense/login_main.dart';
import 'package:dollar_sense/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'login_screen.dart';

class MyAccount extends StatefulWidget {

  final String username, email;

  MyAccount({required this.username, required this.email});

  @override
  _MyAccountState createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  File? _image;
  String _username = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    try {
      // Get the current user ID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Retrieve user data from Firestore using user ID
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .get();

      // Update state with user data
      setState(() {
        _username = userData.get('username') ?? '';
        _email = userData.get('email') ?? '';
      });

      // Debugging: Print retrieved username and email
      print('Retrieved username: $_username');
      print('Retrieved email: $_email');
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFAE5CC),
        title: Text('My Account'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAE5CC),
              Color(0xFF9F8A85),
              Color(0xFF655C56),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : AssetImage('assets/avatar.jpg') as ImageProvider,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Username: ${widget.username}', // Display retrieved username
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Email: ${widget.email}', // Display retrieved email
                style: TextStyle(
                  fontSize: 18,
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
                    MaterialPageRoute(builder: (context) => EditAccount(username: widget.username, email: widget.email)),
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
    );
  }
}