import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transaction_history_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class TransactionHistoryPage extends StatefulWidget {
  final String username;

  const TransactionHistoryPage({required this.username});

  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  List<History> _history = [];
  bool _isLoading = true;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
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
          .orderBy('history_date')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildHistoryList(_history),

      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped: NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }

  Widget _buildHistoryList(List<History> history) {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        History transaction = history[index];
        DateTime date = DateTime.parse(
            transaction.date);
        String formattedDate = DateFormat('yyyy-MM-dd').format(date);

        return Padding(
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
