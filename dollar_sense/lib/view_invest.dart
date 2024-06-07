import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dollar_sense/add_expense_custom_input_view.dart';
import 'package:dollar_sense/invest_model.dart';
import 'package:dollar_sense/invest_view_model.dart';
import 'package:dollar_sense/currency_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dollar_sense/navigation_bar.dart';
import 'package:dollar_sense/speed_dial.dart';
import 'package:dollar_sense/my_account.dart';
import 'package:dollar_sense/edit_invest.dart';

class ViewInvestPage extends StatefulWidget {
  final String username, email;

  const ViewInvestPage({required this.username, required this.email});

  @override
  _ViewInvestPageState createState() => _ViewInvestPageState();
}

class _ViewInvestPageState extends State<ViewInvestPage> {
  int currentIndex = 0;
  int _bottomNavIndex = 0;
  List<Invest> invests = [];

  @override
  void initState() {
    super.initState();
  }

  void _onTabTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MyAccount(username: widget.username, email: widget.email),
        ),
      );
    }
  }

  Future<List<Invest>> _fetchInvest() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot investSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('invest')
          .orderBy('id')
          .get();

      return investSnapshot.docs
          .map((doc) => Invest.fromDocument(doc))
          .toList();
    } else {
      // Return an empty list if no expenses found
      return [];
    }
  }

  void _updateInvest(Invest editedInvest) {
    setState(() {
      // Find the index of the edited expense in the expenses list
      int index =
          invests.indexWhere((invest) => invest.id == editedInvest.id);
      if (index != -1) {
        // Replace the edited expense with the new one
        invests[index] = editedInvest;
      }
    });
  }

  void _editInvest(Invest invest) async {
    // Retrieve the document ID associated with the selected expense
    String documentId = await _getDocumentId(invest);

    // Navigate to the edit expense screen and pass the document ID
    Invest editedInvest = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInvest(
          onInvestUpdated: _updateInvest,
          invest: invest,
          username: widget.username,
          documentId: documentId,
        ),
      ),
    );

    // Check if an expense was edited
    if (editedInvest != null) {
      // Update the UI with the edited expense
      _updateInvest(editedInvest);
    }
  }

  Future<String> _getDocumentId(Invest invest) async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot expenseSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('invest')
          .limit(1)
          .get();

      if (expenseSnapshot.docs.isNotEmpty) {
        return expenseSnapshot.docs.first.id;
      }
    }
    // Return an empty string or handle the case where the document ID is not found
    return '';
  }

  Future<void> _deleteInvest(Invest invest) async {
    String username = widget.username;
    String documentId = await _getDocumentId(invest);
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('invest')
          .doc(documentId) // Specify the document ID of the investment to delete
          .delete();

      setState(() {
        // Remove the deleted investment from the list
        invests.removeWhere((element) => element.id == invest.id);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF988E82),
        title: Text('View Invest'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF988E82),
              Color(0xFFDED2C4),
              Color(0xFFD5C2B0),
            ],
          ),
        ),
        child: FutureBuilder<List<Invest>>(
          future: _fetchInvest(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else if (snapshot.data!.isEmpty) {
              return Center(
                child: Text('No invest found.'),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final invest = snapshot.data![index];
                  final isOdd = index % 2 == 0; // Check if the index is odd

                  return Container(
                    color: isOdd
                        ? Colors.grey[200]!.withOpacity(0.8)
                        : Colors.white!.withOpacity(0.8), // Set background color based on index
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(invest.title),
                          Text(
                            '${invest.date}',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      subtitle: Text('Amount: \RM${invest.amount}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _editInvest(invest);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deleteInvest(invest); // Pass the document ID of the investment
                              },
                            ),
                          ],
                        ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped: _onTabTapped,
      ).build(),
    );
  }
}