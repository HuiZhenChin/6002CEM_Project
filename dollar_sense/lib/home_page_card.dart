import 'package:flutter/material.dart';

class HomePageCard extends StatelessWidget {
  final String title;
  final String amount;

  const HomePageCard({
    Key? key,
    required this.title,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: Color(0xFF5B504C), // Set small card background color
        child: Container(
          height: 100.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white, // Set text color to contrast with background
                  ),
                ),
                SizedBox(height: 8.0),
                Center(
                  child: Text(
                    '\ $amount',
                    style: TextStyle(
                      fontSize: 20.0, // Increase font size for the amount
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Set text color to contrast with background
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}