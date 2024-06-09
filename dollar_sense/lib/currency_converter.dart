import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'currency_converter_view_model.dart';
import 'currency_converter_model.dart';

class CurrencyConverterPage extends StatefulWidget {
  final String username;
  final Function(Currency) onCurrencyAdded;

  const CurrencyConverterPage({required this.username, required this.onCurrencyAdded});

  @override
  _CurrencyConverterPageState createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final String currencyApiUrl =
      'https://v6.exchangerate-api.com/v6/dc09aa4614dcaa1eec9bd34d/latest/MYR';

  Map<String, dynamic>? currencyData;
  String selectedCurrency = 'USD';
  late TextEditingController amountController;
  late TextEditingController convertedAmountController;
  final viewModel= CurrencyConverterViewModel();


  @override
  void initState() {
    super.initState();
    fetchCurrencyData();
    amountController = TextEditingController();
    convertedAmountController = TextEditingController();
  }

  Future<void> fetchCurrencyData() async {
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
                String currency =
                currencyData!['conversion_rates'].keys.elementAt(index);
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
                String currency =
                currencyData!['conversion_rates'].keys.elementAt(index);
                double rate =
                currencyData!['conversion_rates'][currency];
                return ListTile(
                  title: Text(currency),
                  onTap: () {
                    setState(() {
                      selectedCurrency = currency;
                      viewModel.codeController.text = currency;
                      viewModel.rateController.text = rate.toStringAsFixed(2);
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

  double convertAmount(double amount, String fromCurrency, String toCurrency,
      Map<String, dynamic> rates) {
    double fromRate = rates[fromCurrency];
    double toRate = rates[toCurrency];
    return amount * (1 / toRate); // Multiply amount by exchange rate
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Converter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Currency: MYR (Malaysian Ringgit)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Conversion Rates:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: currencyData != null
                  ? ListView.builder(
                itemCount: currencyData!['conversion_rates'].length,
                itemBuilder: (context, index) {
                  String currency =
                  currencyData!['conversion_rates'].keys.elementAt(index);
                  double rate =
                  currencyData!['conversion_rates'][currency];
                  return ListTile(
                    title: Text(currency),
                    trailing: Text(rate.toStringAsFixed(2)),
                  );
                },
              )
                  : CircularProgressIndicator(),
            ),
            SizedBox(height: 20),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Enter Amount'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            TextField(
              controller: viewModel.codeController,
              decoration: InputDecoration(labelText: 'Selected Currency'),
              enabled: false,
            ),
            SizedBox(height: 20),
            TextField(
              controller: viewModel.rateController,
              decoration: InputDecoration(labelText: 'Conversion Rate'),
              enabled: false,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showCurrencyDialog,
              child: Text('Test Currency'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showCurrencyPickerDialog,
              child: Text('Choose Currency'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                   viewModel.addCurrency(widget.username, widget.onCurrencyAdded, context);
                  },
                  child: Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Cancel action
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}