import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordPage extends StatefulWidget {
  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter your email address to reset your password',
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 20.0),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email address';
                }
                return null;
              },
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _resetPassword(context),
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  //ask user to enter email to send reset password link
  Future<void> _resetPassword(BuildContext context) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter your email address.'),
        backgroundColor: Colors.red,
      ));
      return;
    }


    setState(() {
      _isLoading = true;
    });

    try {
      //send reset password link to the email entered by user
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Password reset email sent. Please check your inbox.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send password reset email. Please try again later.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
