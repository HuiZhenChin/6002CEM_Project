import 'package:flutter/material.dart';
import 'package:dollar_sense/colour.dart';
import 'package:dollar_sense/addExpenseJson.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddExpensePage extends StatefulWidget {
  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  List<Expense> expenses = [];
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  String selectedCategory = 'Food';
  String selectedPaymentMethod = 'Cash';
  File? receiptImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Planner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ['Food', 'Transport', 'Entertainment', 'Other']
                    .map((category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: ['Cash', 'Card', 'Online', 'Other']
                    .map((method) => DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                  });
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      dateController.text = pickedDate.toLocal().toString().split(' ')[0];
                    });
                  }
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      timeController.text = pickedTime.format(context);
                    });
                  }
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                  setState(() {
                    if (pickedFile != null) {
                      receiptImage = File(pickedFile.path);
                    }
                  });
                },
                child: Text('Upload Receipt'),
              ),
              receiptImage != null
                  ? Image.file(
                receiptImage!,
                height: 100,
                width: 100,
              )
                  : Container(),
              SizedBox(height: 10),
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
                        addExpense();
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
    );
  }

  void addExpense() {
    String title = titleController.text;
    double amount = double.tryParse(amountController.text) ?? 0.0;
    String description = descriptionController.text;
    String date = dateController.text;
    String time = timeController.text;

    if (title.isNotEmpty && amount > 0) {
      setState(() {
        expenses.add(Expense(
          title: title,
          amount: amount,
          category: selectedCategory,
          paymentMethod: selectedPaymentMethod,
          description: description,
          date: date,
          time: time,
          receiptImage: receiptImage,
        ));
        titleController.clear();
        amountController.clear();
        descriptionController.clear();
        dateController.clear();
        timeController.clear();
        receiptImage = null;
      });
    }
  }
}

class Expense {
  final String title;
  final double amount;
  final String category;
  final String paymentMethod;
  final String description;
  final String date;
  final String time;
  final File? receiptImage;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.description,
    required this.date,
    required this.time,
    this.receiptImage,
  });
}
