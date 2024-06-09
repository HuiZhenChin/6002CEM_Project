import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'currency_converter_model.dart';

class CurrencyConverterViewModel {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController rateController= TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCurrency(String username, Function(Currency) onCurrencyAdded,  BuildContext context) async {
    String code = codeController.text;
    double rate = double.tryParse(rateController.text) ?? 0.0;
    bool converted= false;

        Currency newCurrency = Currency(
            code: code,
            rate: rate,
            converted: converted,
        );

        onCurrencyAdded(newCurrency);
        await _saveCurrencyToFirestore(newCurrency, username, context);
        codeController.clear();
        rateController.clear();
      }


  Future<void> _saveCurrencyToFirestore(Currency currency, String username,
      BuildContext context) async {
    // Query Firestore to get the user ID from the username
    QuerySnapshot userSnapshot = await _firestore
        .collection('dollar_sense')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      String userId = userSnapshot.docs.first.id;
      CollectionReference currencyCollection = FirebaseFirestore.instance
          .collection('dollar_sense')
          .doc(userId)
          .collection('currency');

      Map<String, dynamic> currencyData = {
        'code': currency.code,
        'rate': currency.rate,
        'converted': currency.converted,
      };

      await currencyCollection.add(currencyData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Currency successfully modified!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not found')),
      );
    }
  }
}