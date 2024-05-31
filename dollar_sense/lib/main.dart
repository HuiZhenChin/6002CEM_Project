import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:dollar_sense/home_page_card.dart';
import 'package:dollar_sense/main_card.dart';
import 'package:dollar_sense/navigation_bar.dart';
import 'package:dollar_sense/add_expense.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/addExpense': (context) => AddExpensePage(), // Route for CreateExpensePage
        // Other routes...
      },
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFFAE5CC),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFAE5CC),
                Color(0xFF9F8A85),
                Color(0xFF655C56),
              ],
            ),
          ), // Set screen background color
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: IconButton(
                        icon: Icon(Icons.attach_money),
                        iconSize: 30,
                        onPressed: () {
                          // Implement action for money converter
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: IconButton(
                        icon: Icon(Icons.history),
                        iconSize: 30,
                        onPressed: () {
                          // Implement action for history
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Hey, user',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Card for displaying current net worth
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: MainCard(
                  title: "Current Net Worth",
                  amount: '31758.88',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: HomePageCard(
                            title: 'Income',
                            amount: '40,000',
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: HomePageCard(
                            title: 'Expense',
                            amount: '3,245.15',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: HomePageCard(
                            title: 'Budget',
                            amount: '8,500.00',
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: HomePageCard(
                            title: 'Invest',
                            amount: '5,000.00',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) {
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
                  onTap: () => print('Income'),
                ),
                SpeedDialChild(
                  child: Icon(Icons.format_list_bulleted_sharp),
                  backgroundColor: Colors.green,
                  label: 'Expense',
                  onTap: () {
                    Navigator.pushNamed(context, '/addExpense');
                  },
                ),
                SpeedDialChild(
                  child: Icon(Icons.calculate_outlined),
                  backgroundColor: Colors.blue,
                  label: 'Budget',
                  onTap: () {

                  },
                ),
                SpeedDialChild(
                  child: Icon(Icons.auto_graph),
                  backgroundColor: Colors.orange,
                  label: 'Invest',
                  onTap: () => print('Invest'),
                ),
              ],
            );
          }
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: CustomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTabTapped: (index) => setState(() {
            _bottomNavIndex = index;
          }),
        ).build(),
      ),
    );
  }
}


