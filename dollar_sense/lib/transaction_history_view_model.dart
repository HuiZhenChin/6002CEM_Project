import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'transaction_history_model.dart';

class TransactionHistoryViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addHistory(String text, DateTime date, String username, BuildContext context) async {
    DateTime date = DateTime.now(); // Get the current date

    History newHistory = History(
      text: text,
      date: date.toString(),
    );

    await _saveHistoryToFirestore(newHistory, username, context);
  }

  Future<void> _saveHistoryToFirestore(History history, String username, BuildContext context) async {
    try {
      QuerySnapshot userSnapshot = await _firestore
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        CollectionReference historyCollection = FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('history');

        Map<String, dynamic> historyData = {
          'history_text': history.text,
          'history_date': history.date,
        };

        await historyCollection.add(historyData);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

}