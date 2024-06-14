import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

//customized input format for amount in the system
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    //parse the new value as an integer
    int value = int.parse(newValue.text.replaceAll('.', ''));

    //format the integer as a decimal string
    String newText = (value / 100).toStringAsFixed(2);

    //return the new value with the formatted text
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
