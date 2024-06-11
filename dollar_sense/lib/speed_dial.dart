import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class CustomSpeedDial extends StatefulWidget {
  @override
  _CustomSpeedDialState createState() => _CustomSpeedDialState();
}

class _CustomSpeedDialState extends State<CustomSpeedDial> {
  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white70,
      overlayColor: Colors.black54,
      overlayOpacity: 0.5,
      children: [
        SpeedDialChild(
          child: Icon(Icons.attach_money),
          backgroundColor: Color(0xFFE9C4CB),
          label: 'Income',
          onTap: () {
            Navigator.pushNamed(context, '/income');
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.wallet),
          backgroundColor: Color(0xFFC0A3C0),
          label: 'Expense',
          onTap: () {
            Navigator.pushNamed(context, '/addExpenses');
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.calculate_outlined),
          backgroundColor: Color(0xFF9284B4),
          label: 'Budget',
          onTap: () {
            Navigator.pushNamed(context, '/budget');
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.auto_graph),
          backgroundColor: Color(0xFF5467AA),
          label: 'Invest',
          onTap: () {
            Navigator.pushNamed(context, '/invest');
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.category_rounded),
          backgroundColor: Color(0xFF1E50A1),
          label: 'Category',
          onTap: () {
            Navigator.pushNamed(context, '/category');
          },
        ),
      ],
    );
  }
}
