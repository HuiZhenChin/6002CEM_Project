import 'package:dollar_sense/FirebaseAPI.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dollar_sense/constants.dart';
import 'app_main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dollar_sense/FirebaseAPI.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyDi5bSQewZitC4aTXrsvag9BBoh8CjZe5U',
        appId: '1:1092645709341:android:899bf97d577cd909ad08f4',
        messagingSenderId: '1092645709341',
        projectId: 'dollarsense-c1f43',
      ),
    );
    runApp(MyLogin());
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Handle error as needed
  }
}

class MyLogin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        snackBarTheme: const SnackBarThemeData(
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(colorPrimary),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey.shade800,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        snackBarTheme: const SnackBarThemeData(
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(colorPrimary),
          brightness: Brightness.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
      color: const Color(colorPrimary),
      home: const HomePage(),
    );
  }
}