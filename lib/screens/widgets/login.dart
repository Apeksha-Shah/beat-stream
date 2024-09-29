import 'package:beat_stream/global/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../authenticate/authenticate.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;
  String? _message;
  bool _isSigning = false;

  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSigning = true;
      });

      try {
        String email = _emailController.text;
        String password = _passwordController.text;
        User? user = await _auth.signInWithEmailAndPassword(email, password);

        if (user != null) {
          setState(() {
            _message = "User successfully logged in";
          });
          var sessionManager = SessionManager();
          await sessionManager.set("name", "cool user");
          await sessionManager.set("id", user.uid);
          await sessionManager.set("isLoggedIn", true);

          showToast(message: "User successfully logged in");

          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushNamed(context, '/');
          });
        } else {
          setState(() {
            _message = "Email or Password is Incorrect";
          });
          showToast(message: "Email or Password is Incorrect");
        }
      } catch (e) {
        setState(() {
          _message = "An error occurred during Sign-in: $e";
        });
        showToast(message: "Error: $e");
      } finally {
        setState(() {
          _isSigning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'beat-stream',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF001A2D),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Login',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.red,
                    ),
                  ),
                ),
              SizedBox(height: 20.0),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF001A2D)),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF001A2D)),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF001A2D),
                ),
                child: _isSigning
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text(
                  'Don\'t have an account? Register',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                onPressed: () async {
                   _signIn();
                },
                icon: Icon(
                  FontAwesomeIcons.google,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Color(0xFF002B40),
    );
  }
}
