import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // If the new value is empty, return it
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Parse the new value as an integer
    int value = int.parse(newValue.text.replaceAll('.', ''));

    // Format the integer as a decimal string
    String newText = (value / 100).toStringAsFixed(2);

    // Return the new value with the formatted text
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
