import 'package:flutter/material.dart';

//customized 4 cards in the Home Page for budget, income, invest and expenses
class HomePageCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final VoidCallback onIconPressed;

  const HomePageCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.onIconPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        child: Card(
          color: Color(0xFF476586),
          child: Container(
            height: 100.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onIconPressed,
                        child: Icon(
                          icon,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Center(
                    child: Text(
                      '\ $amount',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}