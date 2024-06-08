import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'budget_view_model.dart';
import 'currency_input_formatter.dart';
import 'budget_model.dart';
import 'add_expense_custom_input_view.dart';

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
  String selectedCategory= "";
  final viewModel = BudgetViewModel();

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
        Map<String, dynamic>? userData = userSnapshot.docs.first.data() as Map<String, dynamic>?;

        setState(() {
          _budgetCategories = (userData?['budget_category'] as List<dynamic>?)?.cast<String>() ?? [];
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: User not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching categories: $e')),
      );
    }
  }

  void showCategoryDialog() {
    _fetchBudgetCategories();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Select Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: _budgetCategories
                    .map((category) => RadioListTile<String>(
                  title: Text(category),
                  value: category,
                  groupValue: selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                      viewModel.categoryController.text = selectedCategory;
                    });
                    Navigator.of(context).pop();
                  },
                ))
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFAE5CC),
        title: Text('Budget'),
        actions: [
          IconButton(
            icon: Icon(Icons.format_list_bulleted_sharp),
            onPressed: () {

            },
          ),
        ],
      ),
      body: Container( // Wrap with Container for gradient background
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
                      // Category input
                      SizedBox(height: 10),
                      // Title input
                      CustomInputField(
                        controller: viewModel.categoryController,
                        labelText: 'Category',
                        inputFormatters: [],
                        onTap: () => showCategoryDialog(),
                      ),
                      SizedBox(height: 10),
                      // Amount input
                      CustomInputField(
                        controller: viewModel.amountController,
                        labelText: 'Amount',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                      ),
                      SizedBox(height: 20),
                      // Cancel and Add buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Color(0xFF52444E), // Change to your preferred background color
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent, // Transparent background
                                    elevation: 0, // No shadow
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
                                  color: Color(0xFF332B28), // Change to your preferred background color
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      bool categoryExists = await viewModel.checkCategoryExists(widget.username, viewModel.categoryController.text.trim());
                                      if (categoryExists) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Category already exists')),
                                        );
                                        return;
                                      } else {
                                        await viewModel.addBudget(widget.onBudgetAdded, widget.username, context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('New Budget Added!')),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to add budget')),
                                      );
                                    }
                                    Navigator.pop(context);
                                  },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent, // Transparent background
                                    elevation: 0, // No shadow
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
    );
  }
}