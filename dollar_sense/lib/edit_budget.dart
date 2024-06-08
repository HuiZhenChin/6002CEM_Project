import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'budget_view_model.dart';
import 'currency_input_formatter.dart';
import 'budget_model.dart';
import 'add_expense_custom_input_view.dart';
import 'transaction_history_view_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class EditBudget extends StatefulWidget {
  final Function(Budget) onBudgetUpdated;
  final String username;
  final Budget budget;
  final String documentId;

  const EditBudget(
      {required this.onBudgetUpdated,
        required this.username,
        required this.budget,
        required this.documentId});

  @override
  _EditBudgetState createState() => _EditBudgetState();
}

class _EditBudgetState extends State<EditBudget> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  final historyViewModel = TransactionHistoryViewModel();
  int _bottomNavIndex = 0;

  late TextEditingController amountController;
  late TextEditingController monthController;
  late TextEditingController yearController;

  late double originalAmount;
  late String originalMonth;
  late String originalYear;

  @override
  void initState() {
    super.initState();
    amountController =
        TextEditingController(text: widget.budget.amount.toString());
    monthController = TextEditingController(text: widget.budget.month);
    yearController = TextEditingController(text: widget.budget.year);

    // Store the original values
    originalAmount = widget.budget.amount;
    originalMonth = widget.budget.month;
    originalYear = widget.budget.year;
  }

  @override
  void dispose() {
    amountController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  void _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      Budget updatedBudget = Budget(
        id: widget.budget.id,
        category: widget.budget.category,
        amount: double.parse(amountController.text),
        month: monthController.text,
        year: yearController.text,
      );

      try {
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
              .collection('budget')
              .doc(widget.documentId)
              .update(updatedBudget.toMap());
        }

        String specificText = "Edit Budget: ${widget.budget.category} ";
        await historyViewModel.addHistory(specificText, widget.username, context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget updated'),
          ),
        );

        widget.onBudgetUpdated(updatedBudget);

        setState(() {
          _isSaving = false;
        });
      } catch (error) {
        print('Error updating budget: $error');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update budget'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    // Set controllers' text back to original values
    amountController.text = originalAmount.toString();
    monthController.text = originalMonth;
    yearController.text = originalYear;

    setState(() {
      _isSaving = false;
    });
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount cannot be empty';
    }
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
      return 'Please enter a valid number';
    }
    double amountValue = double.parse(value);
    if (amountValue <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  Future<void> _pickMonthAndYear(BuildContext context) async {
    int? selectedYear;
    String? selectedMonth;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Month and Year'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButton<String>(
                hint: Text('Select Month'),
                value: selectedMonth,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedMonth = newValue;
                  });
                },
                items: DateFormat.MMMM().dateSymbols.MONTHS.map((String month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
              ),
              DropdownButton<int>(
                hint: Text('Select Year'),
                value: selectedYear,
                onChanged: (int? newValue) {
                  setState(() {
                    selectedYear = newValue;
                  });
                },
                items: List.generate(101, (index) => 2000 + index).map((int year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                setState(() {
                  if (selectedMonth != null) {
                    monthController.text = selectedMonth!;
                  }
                  if (selectedYear != null) {
                    yearController.text = selectedYear.toString();
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFAE5CC),
        title: Text('Edit Budget'),

      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAE5CC),
              Color(0xFF9F8A85),
              Color(0xFF6E655E),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: TextEditingController(
                            text: widget.budget.category),
                        labelText: 'Category',
                        inputFormatters: [],
                        readOnly: true,
                      ),
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: amountController,
                        labelText: 'Amount',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: _validateAmount,
                      ),
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: monthController,
                        labelText: 'Month',
                        inputFormatters: [],
                        onTap: () => _pickMonthAndYear(context),
                        validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Please select a month'
                            : null,
                      ),
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: yearController,
                        labelText: 'Year',
                        inputFormatters: [],
                        onTap: () => _pickMonthAndYear(context),
                        validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Please select a year'
                            : null,
                      ),
                      SizedBox(height: 20),
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
                                    Navigator.pop(context); // Dismiss the EditBudget screen
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
                                  onPressed: _isSaving ? null : _saveBudget,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                  ),
                                  child: _isSaving
                                      ? CircularProgressIndicator()
                                      : Text(
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
            ),
          ],
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
