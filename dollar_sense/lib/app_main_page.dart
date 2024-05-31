import 'package:dollar_sense/main.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/background.jpg', // Replace with your image path
            fit: BoxFit.cover,
          ),
          // Centered Title Text with additional text below
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 20),
                Text(
                  'Dollar Sense', // Replace with your title text
                  style: TextStyle(
                    fontSize: 36, // Adjust the font size as needed
                    color: Colors.black, // Adjust the text color as needed
                    fontWeight:
                    FontWeight.bold, // Adjust the font weight as needed
                  ),
                ),
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    color: Colors.black, // Color of the line
                    thickness: 1, // Thickness of the line
                    indent: 50, // Optional: for adding start padding
                    endIndent: 50, // Optional: for adding end padding
                  ),
                ),
                Text(
                  'Your daily financial necessity', // Replace with your additional text
                  style: TextStyle(
                    fontSize: 14, // Adjust the font size as needed
                    color: Colors.black, // Adjust the text color as needed
                  ),
                ),
              ],
            ),
          ),
          // Bottom Buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 150, // Adjust the width as needed
                    height: 50, // Adjust the height as needed
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Background color
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text(
                        'LOG IN',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20), // Add spacing between the buttons
                  SizedBox(
                    width: 150, // Adjust the width as needed
                    height: 50, // Adjust the height as needed
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Background color
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterPage()),
                        );
                      },
                      child: Text(
                        'REGISTER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
