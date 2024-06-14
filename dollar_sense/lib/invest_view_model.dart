import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'invest_model.dart';

//invest view model
class InvestViewModel {
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //insert new investment
  Future<void> addInvest(Function(Invest) onInvestAdded, String username, BuildContext context) async {
    String title = titleController.text;
    double amount = double.tryParse(amountController.text) ?? 0.0;
    String date = dateController.text;

    if (title.isNotEmpty && amount > 0) {
      DocumentReference counterDoc = FirebaseFirestore.instance
          .collection('counters')
          .doc('investCounter');

      DocumentSnapshot counterSnapshot = await counterDoc.get();

      //get the invest id
      int newInvestId = 1;
      if (counterSnapshot.exists) {
        newInvestId = counterSnapshot['currentId'] as int;
        newInvestId++;

        //update the counter document with the new currentId
        await counterDoc.set({'currentId': newInvestId});


        Invest newInvest = Invest(
            id: newInvestId.toString(),
            title: title,
            amount: amount,
            date: date
        );

        onInvestAdded(newInvest);
        await _saveInvestToFirestore(newInvest, username, context);
        titleController.clear();
        amountController.clear();
        dateController.clear();
      }
    }
  }

    //save to database
    Future<void> _saveInvestToFirestore(Invest invest, String username,
        BuildContext context) async {

      QuerySnapshot userSnapshot = await _firestore
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        CollectionReference investCollection = FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('invest');

        Map<String, dynamic> investData = {
          'id': invest.id,
          'invest_title': invest.title,
          'invest_amount': invest.amount,
          'invest_date': invest.date
        };

        await investCollection.add(investData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invest successfully added')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: User not found')),
        );
      }
    }
  }



