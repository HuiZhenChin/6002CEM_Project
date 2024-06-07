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
          backgroundColor: Colors.red,
          label: 'Income',
          onTap: () {
            Navigator.pushNamed(context, '/income');
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.wallet),
          backgroundColor: Colors.green,
          label: 'Expense',
          onTap: () {
            Navigator.pushNamed(context, '/addExpenses');
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.calculate_outlined),
          backgroundColor: Colors.blue,
          label: 'Budget',
          onTap: () {
            Navigator.pushNamed(context, '/budget');
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.auto_graph),
          backgroundColor: Colors.orange,
          label: 'Invest',
          onTap: () {
            Navigator.pushNamed(context, '/invest');
          },
        ),
      ],
    );
  }
}
