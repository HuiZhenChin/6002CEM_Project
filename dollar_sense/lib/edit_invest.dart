import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'invest_model.dart';
import 'add_expense_view_model.dart';
import 'add_expense_custom_input_view.dart';
import 'currency_input_formatter.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

//page to edit investments
class EditInvest extends StatefulWidget {
  final Function(Invest) onInvestUpdated;
  final String username;
  final Invest invest;
  final String documentId;

  const EditInvest({required this.onInvestUpdated, required this.username, required this.invest, required this.documentId});

  @override
  _EditInvestState createState() => _EditInvestState();
}

class _EditInvestState extends State<EditInvest> {
  int currentIndex = 0;
  final navigationBarViewModel= NavigationBarViewModel();
  int _bottomNavIndex = 0;  //navigation bar position index
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;
  final viewModel = AddExpenseViewModel();

  late TextEditingController titleController;
  late TextEditingController amountController;
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.invest.title);
    amountController = TextEditingController(text: widget.invest.amount.toString());
    dateController = TextEditingController(text: widget.invest.date);

  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    dateController.dispose();
    super.dispose();
  }

  //save changes for investments
  void _saveInvest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      Invest updatedInvest = Invest(
        id: widget.invest.id,
        title: titleController.text,
        amount: double.parse(amountController.text),
        date: dateController.text,
      );

      try {
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
              .collection('invest')
              .doc(widget.documentId)
              .update(updatedInvest.toMap());
        }

        //success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invest updated'),
          ),
        );

        widget.onInvestUpdated(updatedInvest);

        //update UI state
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      } catch (error) {
        //error handling
        print('Error updating invest: $error');

        //failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update invest'),
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
    titleController.text = widget.invest.title;
    amountController.text = widget.invest.amount.toString();
    dateController.text = widget.invest.date;

    //update UI state
    setState(() {
      _isEditing = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Edit Invest'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveInvest,
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
                              primary: Colors.blue.shade900,
                              onPrimary: Colors.white,
                              onSurface: Colors.blue.shade900,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue.shade900,
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      final formattedDate = "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                      dateController.text = formattedDate;
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
                            color: Color(0xFF85A5C3),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _cancelEdit(); //cancel editing
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
                              _saveInvest(); //save changes
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
        onTabTapped: NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }

}