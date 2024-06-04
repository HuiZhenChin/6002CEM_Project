import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/add_expense_model.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;


class AddExpenseViewModel {
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController paymentMethodController = TextEditingController();
  File? receiptImage;

  String selectedCategory = 'Food';
  String selectedPaymentMethod = 'Cash';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Food', 'Transport', 'Entertainment', 'Other']
                .map((category) =>
                RadioListTile<String>(
                  title: Text(category),
                  value: category,
                  groupValue: selectedCategory,
                  onChanged: (value) {
                    selectedCategory = value!;
                    categoryController.text = selectedCategory;
                    Navigator.of(context).pop();
                  },
                ))
                .toList(),
          ),
        );
      },
    );
  }

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

  Future<void> addExpense(Function(Expense) onExpenseAdded, String username, BuildContext context) async {
    String title = titleController.text;
    double amount = double.tryParse(amountController.text) ?? 0.0;
    String description = descriptionController.text;
    String date = dateController.text;
    String time = timeController.text;

    if (title.isNotEmpty && amount > 0) {
      Expense newExpense = Expense(
        title: title,
        amount: amount,
        category: selectedCategory,
        paymentMethod: selectedPaymentMethod,
        description: description,
        date: date,
        time: time,
        receiptImage: receiptImage,
      );

      onExpenseAdded(newExpense);
      await _saveExpenseToFirestore(newExpense, username, context);
      titleController.clear();
      amountController.clear();
      descriptionController.clear();
      dateController.clear();
      timeController.clear();
      receiptImage = null;
    }
  }

  Future<void> _saveExpenseToFirestore(Expense expense, String username, BuildContext context) async {
    // Query Firestore to get the user ID from the username
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
        'title': expense.title,
        'amount': expense.amount,
        'category': expense.category,
        'payment_method': expense.paymentMethod,
        'description': expense.description,
        'date': expense.date,
        'time': expense.time,
        'receipt_image': expense.receiptImage?.path ?? '',
      };

      await expensesCollection.add(expenseData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense successfully added')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not found')),
      );
    }


  }

  // Function to upload image to Firebase Storage
  Future<String> uploadImageToFirebase(File imageFile) async {
    try {
      // Get reference to the storage service
      firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;

      // Create a reference to the location you want to upload the image
      firebase_storage.Reference ref = storage.ref().child('receipts/${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the file to Firebase Storage
      await ref.putFile(imageFile);

      // Get the download URL for the image
      String imageUrl = await ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }
}
