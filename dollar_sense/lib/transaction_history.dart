import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_history_model.dart';

class TransactionHistoryPage extends StatefulWidget {
  final String username;

  const TransactionHistoryPage({required this.username});

  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  List<History> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<List<History>> _fetchHistory() async {
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
          .orderBy('history_date')
          .get();

      return historySnapshot.docs
          .map((doc) => History.fromDocument(doc))
          .toList();
    } else {
      // Return an empty list if no expenses found
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildHistoryList(_history),
    );
  }


  Widget _buildHistoryList(List<History> history) {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        History transaction = history[index];
        return ListTile(
          title: Text(transaction.date), // Assuming date is a property of History class
          subtitle: Text(transaction.text), // Assuming text is a property of History class
        );
      },
    );
  }

}