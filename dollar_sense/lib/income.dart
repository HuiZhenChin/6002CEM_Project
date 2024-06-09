import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'income_view_model.dart';
import 'transaction_history_view_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

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
  final historyViewModel = TransactionHistoryViewModel();
  final _formKey = GlobalKey<FormState>();
  final navigationBarViewModel= NavigationBarViewModel();
  int _bottomNavIndex = 0;


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

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _saveIncome();
        String specificText = "Income: ${_viewModel.incomeController.text}";
        historyViewModel.addHistory(specificText, widget.username, context);
      }
    });
  }

  void _saveIncome() {
    if (_formKey.currentState?.validate() ?? false) {
      double newIncome = double.tryParse(_viewModel.incomeController.text) ??
          0.0;
      _viewModel.saveIncomeToFirestore(widget.username, newIncome, context);
      setState(() {
        _fetchedIncome = newIncome;
        _isEditing = false;
      });
      widget.onIncomeUpdated(); // Notify that income has been updated
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Income successfully modified')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please correct the income amount')),
      );
    }
  }


  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _viewModel.incomeController.text = _fetchedIncome.toString();
    });
  }

  String? _validateIncome(String? value) {
    if (value == null || value.isEmpty) {
      return 'Income cannot be empty';
    }
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
      return 'Please enter a valid number';
    }
    double incomeValue = double.parse(value);
    if (incomeValue <= 0) {
      return 'Income must be greater than 0';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFAE5CC),
        title: Text('Income'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEdit,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAE5CC),
              Color(0xFF9F8A85),
              Color(0xFF423D39),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
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
                SizedBox(height: 30),
                TextFormField(
                  controller: _viewModel.incomeController,
                  enabled: _isEditing,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter your income',
                    floatingLabelStyle: TextStyle(color: Colors.black),
                    fillColor: Color(0xFFEAD9CF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  validator: _validateIncome,
                ),

                SizedBox(height: 20),
                if (_isEditing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _cancelEdit,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xFF52444E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          side: BorderSide(color: Color(0xFF2C2429)),
                        ),
                        child: Text('Cancel'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped: NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }

}