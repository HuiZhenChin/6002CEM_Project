import 'view_budget.dart';
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

class BudgetPage extends StatefulWidget {
  final String username;
  final Function(Budget) onBudgetAdded;

  const BudgetPage({required this.username, required this.onBudgetAdded});

  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _formKey = GlobalKey<FormState>();
  List<String> _budgetCategories = [];
  bool _isLoading = true;
  String selectedCategory = "";
  final viewModel = BudgetViewModel();
  final historyViewModel = TransactionHistoryViewModel();
  final navigationBarViewModel= NavigationBarViewModel();
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchBudgetCategories();

  }

  Future<void> _fetchBudgetCategories() async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: widget.username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        Map<String, dynamic>? userData =
        userSnapshot.docs.first.data() as Map<String, dynamic>?;

        setState(() {
          _budgetCategories = (userData?['budget_category'] as List<dynamic>?)
              ?.cast<String>() ??
              [];
          _isLoading = false;
        });

        if (_budgetCategories.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No category created, you may create a category through "+" -> category',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No category created, you may create a category through "+" -> category',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching categories: $e'),
        ),
      );
    }
  }

  void showCategoryDialog() async {
    await _fetchBudgetCategories();
    String selectedCategory = viewModel.categoryController.text;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Select Category'),
              content: _budgetCategories.isEmpty
                  ? Text('No category created, you may create a category through "+" -> category')
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: _budgetCategories
                    .map((category) => RadioListTile<String>(
                  title: Text(category),
                  value: category,
                  groupValue: selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ))
                    .toList(),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update the category only if it's different from the original
                    if (selectedCategory != viewModel.categoryController.text) {
                      setState(() {
                        viewModel.categoryController.text = selectedCategory;
                      });
                    }
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a category';
    }
    return null;
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
                      viewModel.monthController.text = selectedMonth!;
                    }
                    if (selectedYear != null) {
                      viewModel.yearController.text = selectedYear.toString();
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
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Budget'),
        actions: [
          IconButton(
            icon: Icon(Icons.format_list_bulleted_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ViewBudgetPage(username: widget.username),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEEF4F8),
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
                        controller: viewModel.categoryController,
                        labelText: 'Category',
                        inputFormatters: [],
                        onTap: () => showCategoryDialog(),
                        validator: _validateCategory,
                      ),
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: viewModel.amountController,
                        labelText: 'Amount',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: _validateAmount,
                      ),
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: viewModel.monthController,
                        labelText: 'Month',
                        inputFormatters: [],
                        onTap: () => _pickMonthAndYear(context),
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Please select a month' : null,
                      ),
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: viewModel.yearController,
                        labelText: 'Year',
                        inputFormatters: [],
                        onTap: () => _pickMonthAndYear(context),
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Please select a year' : null,
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
                                  color: Color(0xFF85A5C3),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
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
                                  color: Color(0xFF547FA3),
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      bool exists = await viewModel
                                          .checkExists(
                                          widget.username,
                                          viewModel.categoryController.text.trim(),
                                          viewModel.monthController.text, viewModel.yearController.text);
                                      if (exists) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Category already exists')),
                                        );
                                        return;
                                      } else {
                                        await viewModel.addBudget(
                                            widget.onBudgetAdded,
                                            widget.username, context);
                                        String specificText = "Add Budget: ${viewModel.categoryController.text} with ${viewModel.amountController.text}";
                                        await historyViewModel.addHistory(
                                            specificText, widget.username, context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('New Budget Added!')),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'ADD',
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
