import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'income_view_model.dart';

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

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Save logic moved to _saveIncome
        _saveIncome();
      }
    });
  }

  void _saveIncome() {
    double newIncome = double.tryParse(_viewModel.incomeController.text) ?? 0.0;
    _viewModel.saveIncomeToFirestore(widget.username, newIncome, context);
    setState(() {
      _fetchedIncome = newIncome;
    });
    widget.onIncomeUpdated(); // Notify that income has been updated
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _viewModel.incomeController.text = _fetchedIncome.toString();
    });
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
              SizedBox(
                height: 50,
                child: TextFormField(
                  controller: _viewModel.incomeController,
                  enabled: _isEditing,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter your income',
                    floatingLabelStyle: TextStyle(color: Colors.black), // Floating label text color
                    fillColor:  Color(0xFFEAD9CF), // Background color
                    filled: true, // Enable the fill color
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black), // Border color when enabled
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black), // Border color when not focused
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black), // Border color when focused
                    ),
                  ),
                ),
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
                        backgroundColor: Color(0xFF52444E), // Text color
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
    );
  }
}