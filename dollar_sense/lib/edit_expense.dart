import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'add_expense_model.dart';
import 'package:image_picker/image_picker.dart';
import 'add_expense_view_model.dart';
import 'add_expense_custom_input_view.dart';
import 'currency_input_formatter.dart';
import 'transaction_history_view_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class EditExpense extends StatefulWidget {
  final Function(Expense) onExpenseUpdated;
  final String username;
  final Expense expense;
  final String documentId;

  const EditExpense({required this.onExpenseUpdated, required this.username, required this.expense, required this.documentId});

  @override
  _EditExpenseState createState() => _EditExpenseState();
}

class _EditExpenseState extends State<EditExpense> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;
  final viewModel = AddExpenseViewModel();
  final historyViewModel= TransactionHistoryViewModel();
  List<String> _budgetCategories = [];
  bool _isLoading = true;
  int _bottomNavIndex = 0;

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
    titleController = TextEditingController(text: widget.expense.title);
    amountController =
        TextEditingController(text: widget.expense.amount.toString());
    originalCategory = widget.expense.category;
    originalPaymentMethod = widget.expense.paymentMethod;
    categoryController= TextEditingController(text: widget.expense.category.toString());
    paymentMethodController= TextEditingController(text: widget.expense.paymentMethod.toString());
    descriptionController =
        TextEditingController(text: widget.expense.description);
    dateController = TextEditingController(text: widget.expense.date);
    timeController = TextEditingController(text: widget.expense.time);

  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    categoryController.dispose();
    paymentMethodController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      // Construct the updated expense object
      Expense updatedExpense = Expense(
        id: widget.expense.id,
        title: titleController.text,
        amount: double.parse(amountController.text),
        category: categoryController.text,
        paymentMethod: paymentMethodController.text,
        description: descriptionController.text,
        date: dateController.text,
        time: timeController.text,
        receiptImage: widget.expense.receiptImage,
        imageBase64: widget.expense.imageBase64,
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
              .collection('expenses')
              .doc(widget.documentId)
              .update(updatedExpense.toMap());
        }

        String specificText = "Edit Expenses: ${titleController.text}";
        await historyViewModel.addHistory(specificText, widget.username, context);
        // Show a snackbar to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense updated'),
          ),
        );

        widget.onExpenseUpdated(updatedExpense);

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
            content: Text('Failed to update expense'),
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
    titleController.text = widget.expense.title;
    amountController.text = widget.expense.amount.toString();
    categoryController.text = widget.expense.category;
    paymentMethodController.text = widget.expense.paymentMethod;
    descriptionController.text = widget.expense.description;
    dateController.text = widget.expense.date;
    timeController.text = widget.expense.time;


    // Update UI state
    setState(() {
      _isEditing = false;
    });
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
          _budgetCategories = (userData?['expense_category'] as List<dynamic>?)
              ?.cast<String>() ??
              [];
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No category created')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching categories: $e')),
      );
    }
  }

  void showCategoryDialog(BuildContext context) {
    _fetchBudgetCategories();
    // Use a separate variable to track the selected category
    String selectedCategory = originalCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    if (selectedCategory != originalCategory) {
                      setState(() {
                        categoryController.text = selectedCategory;
                      });
                    }
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showPaymentMethodDialog(BuildContext context) {
    // Use a separate variable to track the selected payment method
    String selectedPaymentMethod = originalPaymentMethod;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Cash', 'Card', 'Online', 'Other']
                .map((method) =>
                RadioListTile<String>(
                  title: Text(method),
                  value: method,
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value!;
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
                // Update the payment method only if it's different from the original
                if (selectedPaymentMethod != originalPaymentMethod) {
                  setState(() {
                    paymentMethodController.text = selectedPaymentMethod;
                  });
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
  Widget _buildExpenseImage(Expense expense) {
    if (expense.receiptImage != null || expense.imageBase64 != null) {
      return GestureDetector(
        onTap: () {
          // Implement the image viewer dialog or action here
        },
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _getImageWidget(expense),
        ),
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox.shrink(), // Empty container
      );
    }
  }

  Widget _getImageWidget(Expense expense) {
    if (expense.receiptImage != null) {
      if (kIsWeb) {
        return Image.network(
          widget.expense.receiptImage!.path,
          height: 100,
          width: 100,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          expense.receiptImage!,
          height: 100,
          width: 100,
          fit: BoxFit.cover,
        );
      }
    } else if (expense.imageBase64 != null && expense.imageBase64!.isNotEmpty) {
      return Image.memory(
        base64Decode(expense.imageBase64!),
        height: 100,
        width: 100,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey,
        child: Center(
          child: Text('No Image'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Expense'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveExpense,
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Text fields for editing expense data
              CustomInputField(
                controller: categoryController,
                labelText: 'Category',
                inputFormatters: [],
                onTap: () => showCategoryDialog(context),
              ),
              SizedBox(height: 10),
              // Payment method input
              CustomInputField(
                controller: paymentMethodController,
                labelText: 'Payment Method',
                inputFormatters: [],
                onTap: () => showPaymentMethodDialog(context),
              ),
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
              SizedBox(height: 10),
              // Time input
              CustomInputField(
                controller: timeController,
                labelText: 'Time',
                keyboardType: TextInputType.datetime,
                inputFormatters: [],
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    timeController.text = pickedTime.format(context);
                  }
                },
              ),
              SizedBox(height: 10),
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
                        widget.expense.receiptImage = File(
                            pickedFile.path); // Update receiptImage
                      });
                      // Convert and set base64
                      // Implement your logic to convert the image to base64 if needed
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
                child: _getImageWidget(widget.expense),

              ),
              SizedBox(height: 10),
              widget.expense.receiptImage != null
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Button to remove the picture
                  IconButton(
                    onPressed: () {
                      setState(() {
                        widget.expense.receiptImage = null;
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
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Receipt Picture'),
                                        content: Container(
                                          width: 300,
                                          height: 300,
                                          child: InteractiveViewer(
                                            boundaryMargin:
                                            EdgeInsets.all(20),
                                            minScale: 0.1,
                                            maxScale: 4,
                                            scaleEnabled: true,
                                            child: kIsWeb
                                                ? Image.network(
                                                widget.expense.receiptImage!.path)
                                                : Image.file(
                                              widget.expense.receiptImage!,
                                              fit: BoxFit.cover,
                                            ),
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
                                child: kIsWeb
                                    ? Image.network(
                                    widget.expense.receiptImage!.path)
                                    : Image.file(
                                  widget.expense.receiptImage!,
                                  fit: BoxFit.cover,
                                ),
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
                            _saveExpense();
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
        onTabTapped: NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }

}