import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dollar_sense/add_expense_custom_input_view.dart';
import 'package:dollar_sense/add_expense_model.dart';
import 'package:dollar_sense/add_expense.dart';

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

  void showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Food', 'Transport', 'Entertainment', 'Other']
                .map((category) => RadioListTile<String>(
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
                .map((method) => RadioListTile<String>(
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

  void addExpense(Function(Expense) onExpenseAdded) {
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
      titleController.clear();
      amountController.clear();
      descriptionController.clear();
      dateController.clear();
      timeController.clear();
      receiptImage = null;
    }
  }
}
