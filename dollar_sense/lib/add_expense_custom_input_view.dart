import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//customized text input field
class CustomInputField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  CustomInputField({
    required this.labelText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    required this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(color: Colors.black87, fontSize: 16),
      cursorColor: Color(0xFF004F9B),
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF39383D)),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        fillColor: Color(0xFFE1E3E7),
        filled: true,
        floatingLabelStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        labelStyle: TextStyle(
          color: Color(0xFF000000),
        ),
      ),
      validator: validator,
    );
  }
}
