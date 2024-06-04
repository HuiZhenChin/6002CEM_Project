import 'dart:io';
import 'package:dollar_sense/view_expenses.dart';
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

  @override
  void initState() {
    super.initState();
    viewModel.categoryController.text = viewModel.selectedCategory;
    viewModel.paymentMethodController.text = viewModel.selectedPaymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFAE5CC),
        title: Text('Add Expenses'),
        actions: [
          IconButton(
            icon: Icon(Icons.format_list_bulleted_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViewExpensesPage(username: widget.username)), // Navigate to AddExpensesPage
              );
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
                        labelText: 'Title',
                        inputFormatters: [],
                      ),
                      SizedBox(height: 10),
                      // Amount input
                      CustomInputField(
                        controller: viewModel.amountController,
                        labelText: 'Amount',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                      ),
                      SizedBox(height: 10),
                      // Date input
                      CustomInputField(
                        controller: viewModel.dateController,
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
                            final formattedDate = "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                            viewModel.dateController.text = formattedDate; // Update controller value with formatted date
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
                          );
                          if (pickedTime != null) {
                            viewModel.timeController.text = pickedTime.format(context); // Update controller value
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
                          color: Colors.grey[200], // Set background color for the button
                          borderRadius: BorderRadius.circular(20), // Set border radius
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final pickedFile = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );
                            setState(() {
                              if (pickedFile != null) {
                                viewModel.receiptImage = File(pickedFile.path);
                              }
                            });
                          },
                          child: Text('Upload Receipt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // Set button color to transparent
                            elevation: 0, // Remove button elevation
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Set button padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20), // Set border radius
                              side: BorderSide(color: Colors.black), // Set border color
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                    // Display uploaded image
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black), // Set border color
                          borderRadius: BorderRadius.circular(10), // Set border radius
                        ),
                        child: viewModel.receiptImage != null
                            ? kIsWeb
                            ? Image.network(
                          viewModel.receiptImage!.path,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ) // Use Image.network for web
                            : Image.file(
                          viewModel.receiptImage!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        )
                            : SizedBox.shrink(), // Hide container if no image is selected
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
                            color: Colors.black, // Set icon color to red
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
                                      width: 300, // Set width of the dialog content
                                      height: 300, // Set height of the dialog content
                                      child: GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              double scaleFactor = 1.0; // Initial scale factor
                                              return AlertDialog(
                                                title: Text('Receipt Picture'),
                                                content: Container(
                                                  width: 300, // Set width of the dialog content
                                                  height: 300, // Set height of the dialog content
                                                  child: InteractiveViewer(
                                                    boundaryMargin: EdgeInsets.all(20),
                                                    minScale: 0.1,
                                                    maxScale: 4,
                                                    scaleEnabled: true,
                                                    child: kIsWeb
                                                        ? Image.network(viewModel.receiptImage!.path) // Use Image.network for web
                                                        : Image.file(
                                                      viewModel.receiptImage!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(); // Close the dialog
                                                    },
                                                    child: Text('Close'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: kIsWeb
                                            ? Image.network(viewModel.receiptImage!.path) // Use Image.network for web
                                            : Image.file(
                                          viewModel.receiptImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                        child: Text('Close'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: Icon(Icons.image_search),
                            color: Colors.black, // Set icon color to blue
                          )
                        ],
                      )
                          : SizedBox.shrink(), // Hide row if no image is selected
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
                                  onPressed: () {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      viewModel.addExpense(widget.onExpenseAdded, widget.username, context);
                                      viewModel.uploadImageToFirebase(viewModel.receiptImage!);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Expense Added')),
                                      );
                                      Navigator.pop(context);
                                    }
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