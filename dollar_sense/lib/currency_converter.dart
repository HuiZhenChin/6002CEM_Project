import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'currency_converter_view_model.dart';
import 'currency_converter_model.dart';
import 'navigation_bar_view_model.dart';
import 'navigation_bar.dart';
import 'speed_dial.dart';

class CurrencyConverterPage extends StatefulWidget {
  final String username;
  final Function(Currency) onCurrencyAdded;

  const CurrencyConverterPage({required this.username, required this.onCurrencyAdded});

  @override
  _CurrencyConverterPageState createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  String baseCurrency = 'MYR';
  late String currencyApiUrl;
  Map<String, dynamic>? currencyData;
  String selectedCurrency = 'USD';
  late TextEditingController amountController;
  late TextEditingController convertedAmountController;
  final viewModel = CurrencyConverterViewModel();
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    convertedAmountController = TextEditingController();
    fetchBaseCurrency();
  }

  Future<void> fetchBaseCurrency() async {
    try {
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
          String baseCurrencyCode = currencySnapshot.docs.first['code'];
          setState(() {
            baseCurrency = baseCurrencyCode;
            updateApiUrl(baseCurrency);
            fetchCurrencyAPIData();
          });
        } else {
          // If the user does not have a currency collection, set default to MYR 1.00
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


  void updateApiUrl(String currencyCode) {
    setState(() {
      currencyApiUrl =
      'https://v6.exchangerate-api.com/v6/dc09aa4614dcaa1eec9bd34d/latest/$currencyCode';
    });
  }

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

  void _showCurrencyDialog() {
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
                return ListTile(
                  title: Text(currency),
                  onTap: () {
                    setState(() {
                      selectedCurrency = currency;
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
                      selectedCurrency = currency;
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

  double convertAmount(double amount, String fromCurrency, String toCurrency,
      Map<String, dynamic> rates) {
    double fromRate = rates[fromCurrency];
    double toRate = rates[toCurrency];
    return amount * (toRate / fromRate);
  }

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

          // Update all collections with new currency rates
          await _updateAllCollections(userId, currencyRate, currencyDocRef);
        }
      }
    }
  }


  Future<void> _updateAllCollections(String userId, double currencyRate,
      DocumentReference currencyDocRef) async {
    QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .doc(userId)
        .collection('budget')
        .get();

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

    for (var doc in expenseSnapshot.docs) {
      double expenseAmount = doc['amount'];
      double convertedExpenseAmount = expenseAmount * currencyRate;
      await doc.reference.update({'amount': convertedExpenseAmount});
    }

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
              'Current Currency: $baseCurrency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Conversion Rates:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
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
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Enter Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
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
      floatingActionButton: CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTabTapped: NavigationBarViewModel.onTabTapped(context, widget.username),
      ).build(),
    );
  }
}