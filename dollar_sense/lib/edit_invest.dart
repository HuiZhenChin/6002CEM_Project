import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'invest_model.dart';
import 'add_expense_view_model.dart';
import 'add_expense_custom_input_view.dart';
import 'currency_input_formatter.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class EditInvest extends StatefulWidget {
  final Function(Invest) onInvestUpdated;
  final String username;
  final Invest invest;
  final String documentId;

  const EditInvest({required this.onInvestUpdated, required this.username, required this.invest, required this.documentId});

  @override
  _EditInvestState createState() => _EditInvestState();
}

class _EditInvestState extends State<EditInvest> {
  int currentIndex = 0;
  int _bottomNavIndex = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;
  final viewModel = AddExpenseViewModel();
  String originalCategory = '';
  String originalPaymentMethod = '';
  File? newReceiptImage;

  late TextEditingController titleController;
  late TextEditingController amountController;
  late TextEditingController categoryController;
  late TextEditingController paymentMethodController;
  late TextEditingController descriptionController;
  late TextEditingController dateController;
  late TextEditingController timeController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.invest.title);
    amountController =
        TextEditingController(text: widget.invest.amount.toString());
    dateController = TextEditingController(text: widget.invest.date);

  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    dateController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {

  }


  void _saveInvest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      // Construct the updated expense object
      Invest updatedInvest = Invest(
        id: widget.invest.id,
        title: titleController.text,
        amount: double.parse(amountController.text),
        date: dateController.text,
      );

      try {
        // Get a reference to the document in Firestore
        String username = widget.username;
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
              .doc(widget.documentId)
              .update(updatedInvest.toMap());
        }

        // Show a snackbar to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invest updated'),
          ),
        );

        widget.onInvestUpdated(updatedInvest);

        // Update UI state
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      } catch (error) {
        // Handle any errors that occur during the update process
        print('Error updating expense: $error');

        // Show a snackbar to indicate failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update invest'),
            backgroundColor: Colors.red,
          ),
        );

        // Reset UI state
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    // Reset controllers to original values
    titleController.text = widget.invest.title;
    amountController.text = widget.invest.amount.toString();
    dateController.text = widget.invest.date;

    // Update UI state
    setState(() {
      _isEditing = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Invest'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveInvest,
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Text fields for editing invest data
              SizedBox(height: 10),
              // Title input
              CustomInputField(
                controller: titleController,
                labelText: 'Title',
                inputFormatters: [],
              ),
              SizedBox(height: 10),
              // Amount input
              CustomInputField(
                controller: amountController,
                labelText: 'Amount',
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
              ),
              SizedBox(height: 10),
              // Date input
              CustomInputField(
                controller: dateController,
                labelText: 'Date',
                keyboardType: TextInputType.datetime,
                inputFormatters: [],
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    final formattedDate =
                        "${pickedDate.day}-${pickedDate.month}-${pickedDate
                        .year}";
                    dateController.text = formattedDate;
                  }
                },
              ),
              SizedBox(height: 20),
              // Cancel and Add
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFF52444E),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            _cancelEdit();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                          ),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFF332B28),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            _saveInvest();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                          ),
                          child: Text(
                            'UPDATE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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