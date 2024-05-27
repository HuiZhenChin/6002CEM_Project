import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dollar_sense/constants.dart';
import 'package:dollar_sense/authentication_bloc.dart';
import 'package:dollar_sense/launcher_screen.dart';
import 'package:dollar_sense/loading_cubit.dart';
import 'app_main_page.dart'; // Import the HomePage widget

void main() {
  runApp(MultiRepositoryProvider(
    providers: [
      RepositoryProvider(create: (_) => AuthenticationBloc()),
      RepositoryProvider(create: (_) => LoadingCubit()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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
      home: const HomePage(), // Use the HomePage widget
    );
  }
}
