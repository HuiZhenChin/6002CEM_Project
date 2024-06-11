import 'package:flutter/material.dart';
import 'invest_view_model.dart';
import 'add_expense_custom_input_view.dart';
import 'currency_input_formatter.dart';
import 'invest_model.dart';
import 'view_invest.dart';
import 'transaction_history_view_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class InvestPage extends StatefulWidget {
  final String username;
  final Function(Invest) onInvestAdded;

  const InvestPage({required this.username, required this.onInvestAdded});

  @override
  _InvestPageState createState() => _InvestPageState();
}

class _InvestPageState extends State<InvestPage> {
  final _formKey = GlobalKey<FormState>();
  final viewModel = InvestViewModel();
  final historyViewModel = TransactionHistoryViewModel();
  final navigationBarViewModel = NavigationBarViewModel();
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  String? _validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName cannot be empty';
    }
    if (fieldName == 'Amount' &&
        !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
      return 'Please enter a valid number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Invest'),
        actions: [
          IconButton(
            icon: Icon(Icons.format_list_bulleted_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewInvestPage(
                    username: widget.username,
                  ),
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
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: viewModel.titleController,
                        labelText: 'Title',
                        inputFormatters: [],
                        validator: (value) => _validateField(value, 'Title'),
                      ),
                      SizedBox(height: 10),
                      CustomInputField(
                        controller: viewModel.amountController,
                        labelText: 'Amount',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: (value) => _validateField(value, 'Amount'),
                      ),
                      SizedBox(height: 10),
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
                            lastDate: DateTime.now(),
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  dialogBackgroundColor: Colors.white,
                                  colorScheme: ColorScheme.light(
                                    primary: Colors.blue
                                        .shade900, // Header background color
                                    onPrimary:
                                        Colors.white, // Header text color
                                    onSurface:
                                        Colors.blue.shade900, // Body text color
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors
                                          .blue.shade900, // Button text color
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
                            viewModel.dateController.text = formattedDate;
                          }
                        },
                        validator: (value) => _validateField(value, 'Date'),
                      ),
                      SizedBox(height: 20),
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
                                  onPressed: () async {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      viewModel.addInvest(widget.onInvestAdded,
                                          widget.username, context);
                                      String specificText =
                                          "Add Invest: ${viewModel.titleController.text} with ${viewModel.amountController.text}";
                                      await historyViewModel.addHistory(
                                          specificText,
                                          widget.username,
                                          context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('New Invest Added')),
                                      );
                                      Navigator.pop(context);
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
        onTabTapped:
            NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }
}
