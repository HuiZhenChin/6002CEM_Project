import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomeViewModel {
  final TextEditingController incomeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveIncomeToFirestore(String username, BuildContext context) async {
    // Query Firestore to get the user ID from the username
    QuerySnapshot userSnapshot = await _firestore
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;

      // Save the income directly under the user's document
      Map<String, dynamic> incomeData = {
        'income': incomeController.text,
      };

      await _firestore.collection('dollar_sense').doc(userId).update(incomeData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Income successfully modified')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not found')),
      );
    }
  }


}
