import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'transaction_history_model.dart';

//history view model
class TransactionHistoryViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //insert history record
  Future<void> addHistory(String text, String username, BuildContext context) async {
    DateTime date = DateTime.now();

    History newHistory = History(
      text: text,
      date: date.toString(),
    );

    await _saveHistoryToFirestore(newHistory, username, context);
  }


  //save to database
  Future<void> _saveHistoryToFirestore(History history, String username, BuildContext context) async {
    try {
      //fetch the user document
      QuerySnapshot userSnapshot = await _firestore
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        //get the user ID
        String userId = userSnapshot.docs.first.id;

        CollectionReference historyCollection = _firestore
            .collection('dollar_sense')
            .doc(userId)
            .collection('history');

        //data to be added to the history collection
        Map<String, dynamic> historyData = {
          'history_text': history.text,
          'history_date': history.date,
        };

        //add data to Firestore
        await historyCollection.add(historyData);

      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      //catch and display error messages
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
