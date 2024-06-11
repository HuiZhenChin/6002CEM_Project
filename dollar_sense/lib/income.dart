import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final List<TextEditingController> _incomeControllers = [];
  bool _isEditing = false;
  double _totalIncome = 0.0;
  final _formKey = GlobalKey<FormState>();
  int _bottomNavIndex = 0;
  final historyViewModel = TransactionHistoryViewModel();

  @override
  void initState() {
    super.initState();
    _fetchIncome();
  }

  Future<void> _fetchIncome() async {
    try {
      String username = widget.username;
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        QuerySnapshot incomeSnapshot = await FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('income')
            .get();

        if (incomeSnapshot.docs.isNotEmpty) {
          setState(() {
            _incomeControllers.clear(); // Clear any existing controllers
            for (var doc in incomeSnapshot.docs) {
              double incomeValue = doc['income'] ?? 0.0;
              TextEditingController controller = TextEditingController(text: incomeValue.toString());
              _incomeControllers.add(controller);
            }
            _updateTotalIncome();
          });
        } else {
          setState(() {
            _incomeControllers.clear(); // Clear any existing controllers
            _addIncomeSource(); // Add one empty income source
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching income: $e')),
      );
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _saveIncome();
      }
    });
  }

  void _saveIncome() {
    if (_formKey.currentState?.validate() ?? false) {
      String username = widget.username;
      FirebaseFirestore.instance.collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get()
          .then((userSnapshot) {
        if (userSnapshot.docs.isNotEmpty) {
          String userId = userSnapshot.docs.first.id;
          for (int i = 0; i < _incomeControllers.length; i++) {
            double newIncome = double.tryParse(_incomeControllers[i].text) ?? 0.0;
            FirebaseFirestore.instance.collection('dollar_sense')
                .doc(userId)
                .collection('income')
                .doc('income_source_$i')
                .set({'income': newIncome});
          }
          _updateTotalIncome();
          widget.onIncomeUpdated();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Income successfully modified')),
          );

          // Add record to history table
          String specificText = "Modified Income";
          historyViewModel.addHistory(specificText, widget.username, context);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please correct the income amount')),
      );
    }
  }

  void _addIncomeSource() {
    setState(() {
      _incomeControllers.add(TextEditingController());
    });
    // Add record to history table
    String specificText = "Add Income Source";
    historyViewModel.addHistory(specificText, widget.username, context);
  }

  void _updateTotalIncome() {
    setState(() {
      _totalIncome = _incomeControllers.fold(0.0, (sum, controller) {
        double value = double.tryParse(controller.text) ?? 0.0;
        return sum + value;
      });
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
        backgroundColor: Color(0xFFEEF4F8),
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
          color: Color(0xFFEEF4F8),
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
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _incomeControllers.length,
                    itemBuilder: (context, index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Income Source ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          TextFormField(
                            controller: _incomeControllers[index],
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Enter your income',
                              floatingLabelStyle: TextStyle(color: Colors.black),
                              fillColor: Color(0xFFE1E3E7),
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
                            onChanged: (value) {
                              _updateTotalIncome();
                            },
                          ),
                          SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
                if (_isEditing)
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _addIncomeSource,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF52444E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        side: BorderSide(color: Color(0xFF85A5C3)),
                      ),
                      child: Text('Add Income Source'),
                    ),
                  ),
                SizedBox(height: 20),
                Text(
                  'Total Income: $_totalIncome',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
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
        onTabTapped:
        NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }
}
