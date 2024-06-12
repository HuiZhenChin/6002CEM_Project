import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'currency_converter_view_model.dart';
import 'currency_converter_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

//page to convert the currency for the system
class CurrencyConverterPage extends StatefulWidget {
  final String username;
  final Function(Currency) onCurrencyAdded;

  const CurrencyConverterPage({required this.username, required this.onCurrencyAdded});

  @override
  _CurrencyConverterPageState createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  String baseCurrency = 'MYR';  //set MYR (Malaysian Ringgit) as the base
  late String currencyApiUrl;   //API url
  Map<String, dynamic>? currencyData;  //currency data mapping
  late TextEditingController amountController;  //control the current amount
  late TextEditingController convertedAmountController;  //control the converted amount
  final viewModel = CurrencyConverterViewModel();
  int _bottomNavIndex = 0;  //navigation bar position index

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    convertedAmountController = TextEditingController();
    fetchBaseCurrency();  //fetch the current base currency in the application
  }

  //function to fetch the base currency
  Future<void> fetchBaseCurrency() async {
    try {
      String username = widget.username;
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .where('username', isEqualTo: username)
          .get();

      //if user has done currency conversion in the system before, take that as the base until they change the currency again
      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        CollectionReference currencyCollection = FirebaseFirestore.instance
            .collection('dollar_sense')
            .doc(userId)
            .collection('currency');

        QuerySnapshot currencySnapshot = await currencyCollection.get();

        if (currencySnapshot.docs.isNotEmpty) {
          String baseCurrencyCode = currencySnapshot.docs.first['code'];
          setState(() {
            baseCurrency = baseCurrencyCode;  //retrieve the currency code
            updateApiUrl(baseCurrency);  //update the API url
            fetchCurrencyAPIData();  //fetch the API data
          });
        } else {
          //if the user does not have a currency conversion before, set default to MYR with 1.00
          setState(() {
            baseCurrency = 'MYR';
            updateApiUrl('MYR');
            fetchCurrencyAPIData();
          });
        }
      }
    } catch (e) {
      print('Error fetching base currency: $e');
    }
  }

  //function to update the API url with the currency code
  void updateApiUrl(String currencyCode) {
    setState(() {
      currencyApiUrl =
      'https://v6.exchangerate-api.com/v6/dc09aa4614dcaa1eec9bd34d/latest/$currencyCode';
    });
  }

  //function to fetch the currency API conversion rate data
  Future<void> fetchCurrencyAPIData() async {
    try {
      final response = await http.get(Uri.parse(currencyApiUrl));
      if (response.statusCode == 200) {
        setState(() {
          currencyData = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load currency data');
      }
    } catch (e) {
      print(e);
    }
  }

  //pop-up dialog to allow user to choose a currency
  void _showCurrencyPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Currency'),
          content: currencyData == null
              ? CircularProgressIndicator()
              : Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: currencyData!['conversion_rates'].length,
              itemBuilder: (context, index) {
                String currency = currencyData!['conversion_rates'].keys
                    .elementAt(index);
                double rate = currencyData!['conversion_rates'][currency];
                return ListTile(
                  title: Text(currency),
                  onTap: () {
                    setState(() {
                      baseCurrency = currency;
                      viewModel.codeController.text = currency;
                      viewModel.rateController.text = rate.toStringAsFixed(2);
                      updateRatesForBaseCurrency(currency);
                      updateApiUrl(currency);
                      fetchCurrencyAPIData();
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  //once a currency is chosen, update the base currency for conversion rates
  void updateRatesForBaseCurrency(String baseCurrency) {
    if (currencyData != null) {
      double baseRate = currencyData!['conversion_rates'][baseCurrency];
      Map<String, double> updatedRates = {};
      currencyData!['conversion_rates'].forEach((currency, rate) {
        updatedRates[currency] = rate / baseRate;
      });
      setState(() {
        currencyData!['conversion_rates'] = updatedRates;
      });
    }
  }

  //function to fetch the currency rates
  Future<void> _fetchCurrency() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      CollectionReference currencyCollection = FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('currency');

      QuerySnapshot currencySnapshot = await currencyCollection.get();

      if (currencySnapshot.docs.isNotEmpty) {
        DocumentReference currencyDocRef = currencySnapshot.docs.first
            .reference;
        DocumentSnapshot currencyDocSnapshot = await currencyDocRef.get();

        if (currencyDocSnapshot.exists) {
          double currencyRate = currencyDocSnapshot['rate'];

          //update all collections with new currency rates
          await _updateAllCollections(userId, currencyRate, currencyDocRef);
        }
      }
    }
  }

  //function to update all the expenses, budget, income and investment amount in the system when there is currency conversion
  Future<void> _updateAllCollections(String userId, double currencyRate,
      DocumentReference currencyDocRef) async {
    QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(userId)
        .collection('budget')
        .get();

    //update all budget amount
    for (var doc in budgetSnapshot.docs) {
      double budgetAmount = doc['budget_amount'];
      double convertedBudgetAmount = budgetAmount * currencyRate;
      await doc.reference.update({'budget_amount': convertedBudgetAmount});
    }

    QuerySnapshot investSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(userId)
        .collection('invest')
        .get();

    //update all investment amount
    for (var doc in investSnapshot.docs) {
      double investAmount = doc['invest_amount'];
      double convertedInvestAmount = investAmount * currencyRate;
      await doc.reference.update({'invest_amount': convertedInvestAmount});
    }

    QuerySnapshot incomeSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(userId)
        .collection('income')
        .get();

    //update all income amount
    for (var doc in incomeSnapshot.docs) {
      double income = doc['income'];
      double convertedIncome = income * currencyRate;
      await doc.reference.update({
        'income': convertedIncome,
      });
    }

    QuerySnapshot expenseSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(userId)
        .collection('expenses')
        .get();

    //update all expenses amount
    for (var doc in expenseSnapshot.docs) {
      double expenseAmount = doc['amount'];
      double convertedExpenseAmount = expenseAmount * currencyRate;
      await doc.reference.update({'amount': convertedExpenseAmount});
    }

    //update all amount extracted for notifications purpose
    QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(userId)
        .collection('notifications')
        .get();

    for (var doc in notificationsSnapshot.docs) {
      double budget = doc['budget_amount'];
      double expense = doc['expense_amount'];
      double convertedBudget = budget * currencyRate;
      double convertedExpense = expense * currencyRate;
      await doc.reference.update({
        'budget_amount': convertedBudget,
        'expense_amount': convertedExpense
      });
    }


    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF4F8),
        title: Text('Currency Converter'),
      ),
      body: Container(
        color: Color(0xFFEEF4F8), // Background color for the entire page
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              //display the current base currency
              'Current Currency: $baseCurrency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Conversion Rates:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            //display conversion rate data in a table fetched from API based on the base currency
            Expanded(
              child: currencyData != null
                  ? ListView.builder(
                itemCount: currencyData!['conversion_rates'].length,
                itemBuilder: (context, index) {
                  String currency = currencyData!['conversion_rates'].keys
                      .elementAt(index);
                  double rate =
                  currencyData!['conversion_rates'][currency];
                  return Container(
                    color: currency == baseCurrency
                        ? Color(0xFF78A3CB)
                        : Color(0xFFB3CDE4).withOpacity(0.7),
                    child: ListTile(
                      title: Text(currency),
                      trailing: Text(rate.toStringAsFixed(2)),
                    ),
                  );
                },
              )
                  : CircularProgressIndicator(),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  //if user selects a currency, display it
                  child: TextField(
                    controller: viewModel.codeController,
                    decoration: InputDecoration(
                      labelText: 'Selected Currency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    enabled: false,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: viewModel.rateController,
                    decoration: InputDecoration(
                      labelText: 'Conversion Rate',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    enabled: false,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _showCurrencyPickerDialog,
                  child: Text('Choose Currency'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    //save changes to database to update all amount in the system
                    viewModel.addCurrency(
                        widget.username, widget.onCurrencyAdded, context);
                    _fetchCurrency();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                  child: Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                  child: Text('Cancel'),
                ),
              ],
            ),
          ],
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