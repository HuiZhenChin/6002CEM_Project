import 'login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background.jpg',
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.black, width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
              ),
              child: RegisterForm(),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  late String _email;
  late String _password;
  late String _username;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _register(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        //check if the email already exists in database
        QuerySnapshot emailSnapshot = await _firestore
            .collection('dollar_sense')
            .where('email', isEqualTo: _email)
            .get();

        //if it returns any documents, meaning email already registered in database
        if (emailSnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('An account with this email already exists.'),
            backgroundColor: Colors.red,
          ));
          //exit if email already exists
          return;
        }

        //check if the username already exists in database
        QuerySnapshot usernameSnapshot = await _firestore
            .collection('dollar_sense')
            .where('username', isEqualTo: _username)
            .get();

        //if it returns any documents, meaning username already exists
        if (usernameSnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('This username is already taken.'),
            backgroundColor: Colors.red,
          ));
          //exit if username already exists
          return;
        }

        //go to registration if email and username are unique
        UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        //get the user ID
        String userId = userCredential.user!.uid;

        //save user data to database
        await _firestore.collection('dollar_sense').doc(userId).set({
          'email': _email,
          'password': _password,
          'username': _username,
        });

        //go to Login Page when successfully registered
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email address';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            onSaved: (value) {
              _email = value!;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              return null;
            },
            onSaved: (value) {
              _password = value!;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(labelText: 'Username'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              return null;
            },
            onSaved: (value) {
              _username = value!;
            },
          ),
          SizedBox(height: 35),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: Size(double.infinity, 60),
              ),
              onPressed: () => _register(context),
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
    );
  }
}
