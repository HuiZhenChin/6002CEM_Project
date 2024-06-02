import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dollar_sense/add_expense_custom_input_view.dart';
import 'package:dollar_sense/add_expense_model.dart';
import 'package:dollar_sense/add_expense_view_model.dart';
import 'package:dollar_sense/currency_input_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyDi5bSQewZitC4aTXrsvag9BBoh8CjZe5U',
      appId: '1:1092645709341:android:899bf97d577cd909ad08f4',
      messagingSenderId: '1092645709341',
      projectId: 'dollarsense-c1f43',
    ),
  );
}

class AddExpensePage extends StatelessWidget {
  final Function(Expense) onExpenseAdded;

  const AddExpensePage({required this.onExpenseAdded});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFAE5CC),
        title: Text('Add Expenses'),
        actions: [
          IconButton(
            icon: Icon(Icons.attach_money),
            onPressed: () {
              // Implement action for money converter
            },
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              // Implement action for history
            },
          ),
        ],
      ),
      body: AddExpenseForm(onExpenseAdded: onExpenseAdded),
    );
  }
}

class AddExpenseForm extends StatefulWidget {
  final Function(Expense) onExpenseAdded;

  const AddExpenseForm({required this.onExpenseAdded});

  @override
  _AddExpenseFormState createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final viewModel = AddExpenseViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.categoryController.text = viewModel.selectedCategory;
    viewModel.paymentMethodController.text = viewModel.selectedPaymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAE5CC),
              Color(0xFF9F8A85),
              Color(0xFF655C56),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category input
                CustomInputField(
                  controller: viewModel.categoryController,
                  labelText: 'Category',
                  inputFormatters: [],
                  onTap: () => viewModel.showCategoryDialog(context),
                ),
                SizedBox(height: 10),
                // Payment method input
                CustomInputField(
                  controller: viewModel.paymentMethodController,
                  labelText: 'Payment Method',
                  inputFormatters: [],
                  onTap: () => viewModel.showPaymentMethodDialog(context),
                ),
                SizedBox(height: 10),
                // Title input
                CustomInputField(
                  controller: viewModel.titleController,
                  labelText: 'Title', inputFormatters: [],
                ),
                SizedBox(height: 10),
                // Amount input
                CustomInputField(
                  controller: viewModel.amountController,
                  labelText: 'Amount',
                  keyboardType: TextInputType.number, inputFormatters: [CurrencyInputFormatter()],
                ),
                SizedBox(height: 10),
                // Date input
                CustomInputField(
                  controller: viewModel.dateController,
                  labelText: 'Date',
                  keyboardType: TextInputType.datetime, inputFormatters: [],
                ),
                SizedBox(height: 10),
                // Time input
                CustomInputField(
                  controller: viewModel.timeController,
                  labelText: 'Time',
                  keyboardType: TextInputType.datetime, inputFormatters: [],
                ),
                SizedBox(height: 10),
                // Description input
                CustomInputField(
                  controller: viewModel.descriptionController,
                  labelText: 'Description', inputFormatters: [],
                ),
                SizedBox(height: 20),
                // Upload Receipt button
                ElevatedButton(
                  onPressed: () async {
                    final pickedFile = await ImagePickerPlugin().pickImage(source: ImageSource.gallery);
                    setState(() {
                      if (pickedFile != null) {
                        viewModel.receiptImage = File(pickedFile.path);
                      }
                    });
                  },
                  child: Text('Upload Receipt'),
                ),
                SizedBox(height: 10),
                viewModel.receiptImage != null
                    ? kIsWeb
                    ? Image.network(viewModel.receiptImage!.path) // Use Image.network for web
                    : Image.file(
                  viewModel.receiptImage!,
                  height: 100,
                  width: 100,
                )
                    : Container(),

                SizedBox(height: 20),
                // Cancel and Add buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            viewModel.addExpense(widget.onExpenseAdded);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Expense Added')),
                            );
                          }
                        },
                        child: Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
