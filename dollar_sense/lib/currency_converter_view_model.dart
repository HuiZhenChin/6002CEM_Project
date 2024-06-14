import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'currency_converter_model.dart';

//currency view model
class CurrencyConverterViewModel {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController rateController= TextEditingController();

  Future<void> addCurrency(String username, Function(Currency) onCurrencyAdded, BuildContext context) async {
    String code = codeController.text;
    double rate = double.tryParse(rateController.text) ?? 0.0;

    Currency newCurrency = Currency(
      code: code,
      rate: rate,
    );

    onCurrencyAdded(newCurrency);
    await _saveCurrencyToFirestore(newCurrency, username, context);
    codeController.clear();
    rateController.clear();
  }

  Future<void> _saveCurrencyToFirestore(Currency currency, String username, BuildContext context) async {
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
        String currencyDocId = currencySnapshot.docs.first.id;
        await currencyCollection.doc(currencyDocId).update({
          'code': currency.code,
          'rate': currency.rate,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await currencyCollection.add({
          'code': currency.code,
          'rate': currency.rate,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Currency successfully updated!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not found')),
      );
    }
  }

}