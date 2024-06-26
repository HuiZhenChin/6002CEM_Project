import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_expense_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

//view model for creating new expense
class AddExpenseViewModel {
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController paymentMethodController = TextEditingController();
  File? receiptImage;
  String receiptImageBase64= "";
  String selectedPaymentMethod = 'Cash';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //show the pop-up dialog for payment method selection
  void showPaymentMethodDialog(BuildContext context) {
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
                    selectedPaymentMethod = value!;
                    paymentMethodController.text = selectedPaymentMethod;
                    Navigator.of(context).pop();
                  },
                ))
                .toList(),
          ),
        );
      },
    );
  }

  //load the default image for those expenses that are not created with a receipt image
  //the system will assign a default pic for display purpose
  Future<String> loadDefaultImageAsBase64() async {
    final ByteData bytes = await rootBundle.load('assets/expenses.png');
    final Uint8List list = bytes.buffer.asUint8List();
    return base64Encode(list);
  }

  //insert new expense function
  Future<void> addExpense(Function(Expense) onExpenseAdded, String username, BuildContext context) async {
    String title = titleController.text;
    double amount = double.tryParse(amountController.text) ?? 0.0;
    String category= categoryController.text;
    String description = descriptionController.text;
    String date = dateController.text;
    String time = timeController.text;
    String imageBase64 = '';

    //validate that title is not empty and amount is greater than 0
    if (title.isNotEmpty && amount > 0) {
      //check if no image is uploaded, use default image
      if (receiptImage == null && imageBase64.isEmpty) {
        imageBase64 = await loadDefaultImageAsBase64();
      } else {
        //convert and set base64 for the uploaded image
        imageBase64 = await convertImageToBase64(XFile(receiptImage!.path));

      }
      //get counter for id purpose
      DocumentReference counterDoc = FirebaseFirestore.instance
          .collection('counters')
          .doc('expenseCounter');

      DocumentSnapshot counterSnapshot = await counterDoc.get();

      //get the expense id
      int newExpenseId = 1;
      if (counterSnapshot.exists) {
        newExpenseId = counterSnapshot['currentId'] as int;
        newExpenseId++; // Increment by 1
      }

      //update the counter document with the new currentId
      await counterDoc.set({'currentId': newExpenseId});


      //create new expense object
      Expense newExpense = Expense(
        id: newExpenseId.toString(),
        title: title,
        amount: amount,
        category: category,
        paymentMethod: selectedPaymentMethod,
        description: description,
        date: date,
        time: time,
        receiptImage: receiptImage,
        imageBase64: imageBase64, // use the base64 of the image
      );

      //add the expense using the callback
      onExpenseAdded(newExpense);

      //save the expense to Firestore
      await _saveExpenseToFirestore(newExpense, username, context);

      //clear form fields
      titleController.clear();
      amountController.clear();
      descriptionController.clear();
      dateController.clear();
      timeController.clear();
      receiptImage = null;

    }
  }

  //encode the image to base64
  Future<String> convertImageToBase64(XFile imageFile) async {
    final List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<void> _saveExpenseToFirestore(Expense expense, String username, BuildContext context) async {
    //get the user ID from the username
    QuerySnapshot userSnapshot = await _firestore
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      CollectionReference expensesCollection = FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('expenses');

      Map<String, dynamic> expenseData = {
        'id': expense.id,
        'title': expense.title,
        'amount': expense.amount,
        'category': expense.category,
        'payment_method': expense.paymentMethod,
        'description': expense.description,
        'date': expense.date,
        'time': expense.time,
        'receipt_image': expense.receiptImage?.path ?? '',
        'receipt_image_base64': expense.imageBase64,
      };


      await expensesCollection.add(expenseData);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not found')),
      );
    }


  }

}