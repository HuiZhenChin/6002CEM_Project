import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transaction_history_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

//page to display history records
class TransactionHistoryPage extends StatefulWidget {
  final String username;

  const TransactionHistoryPage({required this.username});

  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  List<History> _history = [];
  bool _isLoading = true;
  final navigationBarViewModel = NavigationBarViewModel();
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();  //fetch history records
  }

  Future<void> _fetchHistory() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot historySnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('history')
          .orderBy('history_date',
          descending: true) //order by history_date in descending order (latest records on top)
          .get();

      setState(() {
        _history = historySnapshot.docs
            .map((doc) => History.fromDocument(doc))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _history = [];
        _isLoading = false;
      });
    }
  }

  //clear history records if user pressed the "Delete" icon
  Future<void> _clearHistory() async {
    try {
      String username = widget.username;
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        QuerySnapshot historySnapshot = await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('history')
            .get();

        List<DocumentReference> documents =
        historySnapshot.docs.map((doc) => doc.reference).toList();

        //delete each document in batches of 500 to avoid exceeding the limit
        //normally there are many records in history
        for (var i = 0; i < documents.length; i += 500) {
          List<DocumentReference> batch = documents.sublist(
              i, (i + 500) > documents.length ? documents.length : i + 500);
          WriteBatch writeBatch = FirebaseFirestore.instance.batch();
          batch.forEach((doc) {
            writeBatch.delete(doc);
          });
          await writeBatch.commit();
        }

        setState(() {
          _history = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('History cleared successfully'),
          ),
        );
      }
    } catch (e) {
      print('Error clearing history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear history'),
        ),
      );
    }
  }

  //show delete confirmation dialog
  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Confirm Clear History'),
          content: Text('Are you sure you want to clear the history?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); //return false to indicate cancel
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); //return true to indicate confirmation
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _clearHistory();  //clear history records
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Transaction History'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],

      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEEF4F8),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _buildHistoryList(_history),
      ),
      //navigation bar
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped: NavigationBarViewModel.onTabTapped(
            context, widget.username),
      ).build(),
    );
  }

  Widget _buildHistoryList(List<History> history) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          //if no history records found
          'No history recorded',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        History transaction = history[index];
        DateTime date = DateTime.parse(transaction.date);
        String formattedDate = DateFormat('yyyy-MM-dd').format(date);

        // Alternating row colors
        Color rowColor = index.isEven ? Colors.grey[200]! : Colors.grey[300]!;

        return Container(
          color: rowColor,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(transaction.text),
              ),
            ],
          ),
        );
      },
    );
  }
}