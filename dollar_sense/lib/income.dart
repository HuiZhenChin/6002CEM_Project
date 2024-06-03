import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/income_view_model.dart';

class IncomePage extends StatefulWidget {
  final String username;
  final Function() onIncomeUpdated;

  const IncomePage({Key? key, required this.username, required this.onIncomeUpdated})
      : super(key: key);

  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final IncomeViewModel _viewModel = IncomeViewModel();
  bool _isEditing = false;
  double _fetchedIncome = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchIncome();
  }

  Future<void> _fetchIncome() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        double incomeValue = userDoc['income'] ?? 0.0;
        setState(() {
          _viewModel.incomeController.text = incomeValue.toString();
          _fetchedIncome = incomeValue;
        });
      }
    }
  }

  /*
  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        double newIncome = double.tryParse(_viewModel.incomeController.text) ?? 0.0;
        _viewModel.saveIncomeToFirestore(widget.username, newIncome);
        widget.onIncomeUpdated(); // Notify that income has been updated
      }
    });
  }
  *
   */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Income'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your Income',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _viewModel.incomeController,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter your income',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _viewModel.incomeController.text = _viewModel.incomeController.text;
                    });
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
            SizedBox(height: 20), // Add space between the rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fetched Income:', // Label for the fetched income amount
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '\$${_fetchedIncome.toStringAsFixed(2)}', // Display the fetched income amount
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
