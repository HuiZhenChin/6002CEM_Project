import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CurrencyConverterPage extends StatefulWidget {
  final String username;

  const CurrencyConverterPage({required this.username});

  @override
  _CurrencyConverterPageState createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final String apiKey = 'dc09aa4614dcaa1eec9bd34d';
  final String apiUrl = 'https://v6.exchangerate-api.com/v6/dc09aa4614dcaa1eec9bd34d/latest/USD';

  double _totalBudget= 0.0;

  Map<String, dynamic>? currencyData;
  String selectedCurrency = 'USD';

  Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'CHF': 'Fr',
    'CNY': '¥',
    'SEK': 'kr',
    'NZD': 'NZ\$',
    // Add more currency codes and symbols as needed
  };

  @override
  void initState() {
    super.initState();
    fetchCurrencyData();
    _fetchTotalBudget();
  }

  Future<void> fetchCurrencyData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
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
                String currency = currencyData!['conversion_rates'].keys.elementAt(index);
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

  double convertAmount(double amount, String fromCurrency, String toCurrency, Map<String, dynamic> rates) {
    double fromRate = rates[fromCurrency];
    double toRate = rates[toCurrency];
    return amount * (toRate / fromRate);
  }

  double get totalBudget {
    return _totalBudget;
  }

  set totalBudget(double value) {
    setState(() {
      _totalBudget = value;
    });
  }

  Future<void> _fetchTotalBudget() async {
    String username = widget.username;
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      QuerySnapshot budgetSnapshot = await FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('budget')
          .get();

      double total = 0.0;
      budgetSnapshot.docs.forEach((doc) {
        total += doc['budget_amount'] as double;
      });

      setState(() {
        totalBudget = total;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double originalAmount = 100.0; // Example amount in USD
    double convertedAmount = currencyData != null
        ? convertAmount(originalAmount, 'USD', selectedCurrency, currencyData!['conversion_rates'])
        : originalAmount;

    String currencySymbol = currencySymbols[selectedCurrency] ?? selectedCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Converter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Selected Currency: $selectedCurrency'),
            Text('Original Amount: \'RM${totalBudget.toStringAsFixed(2)}'),
            Text('Converted Amount: $currencySymbol${convertedAmount.toStringAsFixed(2)}'),
            ElevatedButton(
              onPressed: _showCurrencyDialog,
              child: Text('Change Currency'),
            ),
          ],
        ),
      ),
    );
  }
}