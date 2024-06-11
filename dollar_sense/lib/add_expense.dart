import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_expenses.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'add_expense_custom_input_view.dart';
import 'add_expense_model.dart';
import 'add_expense_view_model.dart';
import 'currency_input_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'transaction_history_view_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

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

class AddExpensePage extends StatefulWidget {
  final Function(Expense) onExpenseAdded;
  final String username;

  const AddExpensePage({required this.onExpenseAdded, required this.username});

  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final viewModel = AddExpenseViewModel();
  final historyViewModel = TransactionHistoryViewModel();
  List<String> _budgetCategories = [];
  bool _isLoading = true;
  String selectedCategory = "";
  final navigationBarViewModel= NavigationBarViewModel();
  int _bottomNavIndex = 0;


  @override
  void initState() {
    super.initState();
    viewModel.paymentMethodController.text = viewModel.selectedPaymentMethod;

  }

  String? _validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName cannot be empty';
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

  Future<void> _fetchExpenseCategories() async {
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
          _budgetCategories = (userData?['expense_category'] as List<dynamic>?)
              ?.cast<String>() ??
              [];
          _isLoading = false;
        });

        if (_budgetCategories.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No category created, you may create a category through "+" -> category')),
          );
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No category created, you may create a category through "+" -> category')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching categories: $e')),
      );
    }
  }

  void showCategoryDialog() {
    _fetchExpenseCategories();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Select Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _budgetCategories.isNotEmpty
                ? _budgetCategories
                .map((category) =>
                RadioListTile<String>(
                  title: Text(category),
                  value: category,
                  groupValue: selectedCategory,
                  onChanged: (value) {
                    selectedCategory = value!;
                    viewModel.categoryController.text = selectedCategory;
                    Navigator.of(context).pop();
                  },
                ))
                .toList()
                : [Text('No category created, you may create a category through "+" -> Category')],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Add Expenses'),
        actions: [
          IconButton(
            icon: Icon(Icons.format_list_bulleted_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ViewExpensesPage(username: widget.username),
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
                      // Category input
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: viewModel.categoryController,
                        labelText: 'Category',
                        inputFormatters: [],
                        onTap: () => showCategoryDialog(),
                        validator: (value) => _validateField(value, 'Category'),
                      ),
                      SizedBox(height: 10),
                      // Payment method input
                      CustomInputField(
                        controller: viewModel.paymentMethodController,
                        labelText: 'Payment Method',
                        inputFormatters: [],
                        onTap: () => viewModel.showPaymentMethodDialog(context),
                        validator: (value) =>
                            _validateField(value, 'Payment Method'),
                      ),
                      SizedBox(height: 10),
                      // Title input
                      CustomInputField(
                        controller: viewModel.titleController,
                        labelText: 'Title',
                        inputFormatters: [],
                        validator: (value) => _validateField(value, 'Title'),
                      ),
                      SizedBox(height: 10),
                      // Amount input
                      CustomInputField(
                        controller: viewModel.amountController,
                        labelText: 'Amount',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: _validateAmount,
                      ),
                      SizedBox(height: 10),
                      // Date input
                      CustomInputField(
                        controller: viewModel.dateController,
                        labelText: 'Date',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: [],
                        validator: (value) => _validateField(value, 'Date'),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  dialogBackgroundColor: Colors.white,
                                  colorScheme: ColorScheme.light(
                                    primary: Colors.blue.shade900, // Header background color
                                    onPrimary: Colors.white, // Header text color
                                    onSurface: Colors.blue.shade900, // Body text color
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue.shade900, // Button text color
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            final formattedDate = "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                            viewModel.dateController.text = formattedDate;
                          }
                        },
                      ),
                      SizedBox(height: 10),
                      // Time input
                      CustomInputField(
                        controller: viewModel.timeController,
                        labelText: 'Time',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: [],
                        onTap: () async {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Colors.blue.shade900, // Header background color
                                    onPrimary: Colors.white, // Header text color
                                    onSurface: Colors.blue.shade900, // Body text color
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime != null) {
                            viewModel.timeController.text = pickedTime.format(context);
                          }
                        },
                      ),
                      SizedBox(height: 10),
                      // Description input
                      CustomInputField(
                        controller: viewModel.descriptionController,
                        labelText: 'Description',
                        inputFormatters: [],
                      ),
                      SizedBox(height: 20),
                      // Upload Receipt button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final pickedFile = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              setState(() {
                                viewModel.receiptImage = File(
                                    pickedFile.path); // Update receiptImage
                              });
                              viewModel.convertImageToBase64(
                                  pickedFile); // Convert and set base64
                            }
                          },
                          child: Text('Upload Receipt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Display uploaded image
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: viewModel.receiptImage != null
                            ? kIsWeb
                                ? Image.network(
                                    viewModel.receiptImage!.path,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    viewModel.receiptImage!,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  )
                            : SizedBox.shrink(),
                      ),
                      SizedBox(height: 10),
                      viewModel.receiptImage != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Button to remove the picture
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      viewModel.receiptImage = null;
                                    });
                                  },
                                  icon: Icon(Icons.delete),
                                  color: Colors.black,
                                ),
                                // Button to view the picture
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Receipt Picture'),
                                          content: Container(
                                            width: 300,
                                            height: 300,
                                            child: GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                          'Receipt Picture'),
                                                      content: Container(
                                                        width: 300,
                                                        height: 300,
                                                        child:
                                                            InteractiveViewer(
                                                          boundaryMargin:
                                                              EdgeInsets.all(
                                                                  20),
                                                          minScale: 0.1,
                                                          maxScale: 4,
                                                          scaleEnabled: true,
                                                          child: kIsWeb
                                                              ? Image.network(
                                                                  viewModel
                                                                      .receiptImage!
                                                                      .path)
                                                              : Image.file(
                                                                  viewModel
                                                                      .receiptImage!,
                                                                  fit: BoxFit
                                                                      .cover),
                                                        ),
                                                      ),
                                                      actions: [
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: Text('Close'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              child: kIsWeb
                                                  ? Image.network(viewModel
                                                      .receiptImage!.path)
                                                  : Image.file(
                                                      viewModel.receiptImage!,
                                                      fit: BoxFit.cover),
                                            ),
                                          ),
                                          actions: [
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Close'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  icon: Icon(Icons.image_search),
                                  color: Colors.black,
                                )
                              ],
                            )
                          : SizedBox.shrink(),
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
                                  onPressed: () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      viewModel.addExpense(
                                          widget.onExpenseAdded,
                                          widget.username,
                                          context);
                                      String specificText =
                                          "Expenses: ${viewModel.titleController.text} with ${viewModel.amountController.text}";
                                      historyViewModel.addHistory(specificText,
                                          widget.username, context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('Expense Added')),
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Please correct the fields')),
                                      );
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
