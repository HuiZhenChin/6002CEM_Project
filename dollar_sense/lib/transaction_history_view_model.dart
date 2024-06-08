import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'transaction_history_model.dart';
import 'package:intl/intl.dart';

class TransactionHistoryViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addHistory(String text, String username, BuildContext context) async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now); // Format the date

    History newHistory = History(
      text: text,
      date: formattedDate,
    );

    await _saveHistoryToFirestore(newHistory, username, context);
  }


  Future<void> _saveHistoryToFirestore(History history, String username, BuildContext context) async {
    try {
      // Fetch the user document
      QuerySnapshot userSnapshot = await _firestore
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        // Get the first matching user document ID
        String userId = userSnapshot.docs.first.id;

        // Reference to the history subcollection
        CollectionReference historyCollection = _firestore
            .collection('dollar_sense')
            .doc(userId)
            .collection('history');

        // Data to be added to the history collection
        Map<String, dynamic> historyData = {
          'history_text': history.text,
          'history_date': history.date,
        };

        // Add data to Firestore
        await historyCollection.add(historyData);

      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      // Catch and display error messages
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
