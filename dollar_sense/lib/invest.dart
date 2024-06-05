import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dollar_sense/invest_view_model.dart';
import 'package:dollar_sense/add_expense_custom_input_view.dart';
import 'package:dollar_sense/currency_input_formatter.dart';
import 'package:dollar_sense/invest_model.dart';
import 'package:dollar_sense/view_invest.dart';

class InvestPage extends StatefulWidget {
  final String username, email;
  final Function(Invest) onInvestAdded;

  const InvestPage({required this.username, required this.onInvestAdded, required this.email});

  @override
  _InvestPageState createState() => _InvestPageState();
}

class _InvestPageState extends State<InvestPage> {
  final _formKey = GlobalKey<FormState>();
  final viewModel = InvestViewModel();

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFAE5CC),
        title: Text('Invest'),
        actions: [
          IconButton(
            icon: Icon(Icons.format_list_bulleted_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                       ViewInvestPage(username: widget.username, email: widget.email)),
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
                                      viewModel.addInvest(widget.onInvestAdded, widget.username, context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('New Invest Added')),
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