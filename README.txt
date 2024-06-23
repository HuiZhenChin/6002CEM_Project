# 6002CEM - Mobile App Development

Assignment Members:
1. Chin Hui Zhen
2. Peh Jia Xuan

Name of Application:
DollarSense

Application Summary:
DollarSense is a financial management mobile application that allows users to manage and organise their monthly income, expenses, investments and budgets. DollarSense focuses on designing interactive features and enhancing good user experience to encourage users to manage their finance in their everyday lives. DollarSense consists of some main features such as category budget settings, budget and bill payments notifications, reports, and currency converter.

IDE Name:
Android Studio

IDE Version:
Hedgehog 2023.1.1 Patch 2

Database:
Firebase

Key Features:
1. Login
2. Register Account
3. Monthly Financial Display
4. Add Expense, Income, Investment, Budget, Category
5. Budget and Reminder Notifications
6. Add Reminder
7. Report Graphs
8. Transaction History
9. Currency Converter
10. User Profile Management

API Integrated:
1. https://www.exchangerate-api.com (to retrieve current currency exchange rate)
2. https://restcountries.com (to retrieve country name)

Third Party Libraries:
1. cupertino_icons: ^1.0.6
2. animated_bottom_navigation_bar: ^1.3.3
3. flutter_speed_dial: ^7.0.0
4. image_picker: ^1.1.1
5. image_picker_for_web: ^3.0.4
6. firebase_core: ^2.32.0
7. firebase_auth: ^4.20.0
8. cloud_firestore: ^4.17.5
9. firebase_storage: ^11.7.7
10. intl: ^0.17.0
11. http: ^1.2.1
12. google_fonts: ^6.2.1
13. table_calendar: ^3.0.1
14. flutter_email_sender: ^5.0.2
15. path_provider: ^2.0.2
16. url_launcher: ^6.3.0
17. fl_chart: ^0.35.0

Additional Steps to Run the Program:
To run the DollarSense program:
1. Install Android Studio and Flutter and Dart plugin.
2. Clone the repository and open the project folder in Android Studio.
3. Modify the `android/app/src/main/AndroidManifest.xml` and `android/app/build.gradle` files with necessary packages and dependencies.
4. Include the Firebase configuration at `android/app/google-services.json` accordingly.
5. Run `flutter pub get` at Android Studio terminal to install the project dependencies.
6. Select an Android emulator or connect to an Android device to launch the application.
7. Launch the program using the Run option at the Android Studio toolbar or run `flutter run` at the terminal.
