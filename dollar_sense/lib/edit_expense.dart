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

//page to edit expenses
class EditExpense extends StatefulWidget {
  final Function(Expense) onExpenseUpdated;
  final String username;
  final Expense expense;
  final String documentId;

  const EditExpense(
      {required this.onExpenseUpdated,
      required this.username,
      required this.expense,
      required this.documentId});

  @override
  _EditExpenseState createState() => _EditExpenseState();
}

class _EditExpenseState extends State<EditExpense> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;
  final viewModel = AddExpenseViewModel();
  final historyViewModel = TransactionHistoryViewModel();
  List<String> _expenseCategories = []; //list of created expenses categories
  bool _isLoading = true;
  final navigationBarViewModel = NavigationBarViewModel();
  int _bottomNavIndex = 0; //navigation bar position index

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
    categoryController =
        TextEditingController(text: widget.expense.category.toString());
    paymentMethodController =
        TextEditingController(text: widget.expense.paymentMethod.toString());
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

  //encode to uploaded image to base64 string
  Future<String> convertImageToBase64(XFile imageFile) async {
    final List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  //save changes for edited expenses
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

      if (widget.expense.receiptImage != null) {
        updatedExpense.imageBase64 = await convertImageToBase64(
            XFile(widget.expense.receiptImage!.path));
      }

      try {
        //get a reference to the document in Firestore
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
        await historyViewModel.addHistory(
            specificText, widget.username, context);
        //snackbar to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense updated'),
          ),
        );

        widget.onExpenseUpdated(updatedExpense);

       //update UI
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      } catch (error) {
        print('Error updating expense: $error');

        //snackbar to indicate failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update expense'),
            backgroundColor: Colors.red,
          ),
        );

        //reset UI state
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    //reset controllers to original values
    titleController.text = widget.expense.title;
    amountController.text = widget.expense.amount.toString();
    categoryController.text = widget.expense.category;
    paymentMethodController.text = widget.expense.paymentMethod;
    descriptionController.text = widget.expense.description;
    dateController.text = widget.expense.date;
    timeController.text = widget.expense.time;

    //update UI state
    setState(() {
      _isEditing = false;
    });
  }

  //fetch the expenses categories
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
          _expenseCategories = (userData?['expense_category'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];
          _isLoading = false;
        });

        //if no expense category found
        if (_expenseCategories.isEmpty) {
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

  //pop-up dialog to choose category
  void showCategoryDialog(BuildContext context) async {
    await _fetchExpenseCategories();
    String selectedCategory = categoryController.text;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Select Category'),
              content: _expenseCategories.isEmpty
                  ? Text(
                //if no category created yet
                      'No category created, you may create a category through "+" -> category')
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _expenseCategories
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
                    if (selectedCategory != categoryController.text) {
                      setState(() {
                        categoryController.text = selectedCategory;
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

  //pop-up dialog to choose payment method for the expenses
  void showPaymentMethodDialog(BuildContext context) {
    //separate variable to track the selected payment method
    String selectedPaymentMethod = originalPaymentMethod;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Cash', 'Card', 'Online', 'Other']
                .map((method) => RadioListTile<String>(
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
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                //update the payment method only if different from the original
                if (selectedPaymentMethod != originalPaymentMethod) {
                  setState(() {
                    paymentMethodController.text = selectedPaymentMethod;
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  //get the image
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
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Edit Expense'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveExpense,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEEF4F8),
        ),
        child: Padding(
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
                      lastDate: DateTime.now(),
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            dialogBackgroundColor: Colors.white,
                            colorScheme: ColorScheme.light(
                              primary: Colors
                                  .blue.shade900,
                              onPrimary: Colors.white,
                              onSurface:
                                  Colors.blue.shade900,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Colors.blue.shade900,
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      final formattedDate =
                          "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
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
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Colors
                                  .blue.shade900,
                              onPrimary: Colors.white,
                              onSurface:
                                  Colors.blue.shade900,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Colors.blue.shade900,
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedTime != null) {
                      timeController.text = pickedTime.format(context);
                    }
                  },
                ),
                SizedBox(height: 10),
                //Upload Receipt button
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
                          widget.expense.receiptImage =
                              File(pickedFile.path); //Update receiptImage
                        });

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
                //display uploaded image
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
                          //button to remove the uploaded picture
                          IconButton(
                            onPressed: () {
                              setState(() {
                                widget.expense.receiptImage = null;
                              });
                            },
                            icon: Icon(Icons.delete),
                            color: Colors.black,
                          ),
                          //button to view the picture
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
                                                        ? Image.network(widget
                                                            .expense
                                                            .receiptImage!
                                                            .path)
                                                        : Image.file(
                                                            widget.expense
                                                                .receiptImage!,
                                                            fit: BoxFit.cover,
                                                          ),
                                                  ),
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
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
                                            ? Image.network(widget
                                                .expense.receiptImage!.path)
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
                            color: Color(0xFF85A5C3),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _cancelEdit();  //cancel edit
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
                              _saveExpense();  //save changes
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
      ),
      //navigation bar
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
