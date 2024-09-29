import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';


class SettingScreen extends StatefulWidget {
  SettingScreen();
  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {

  String value = "Sign In";

  @override
  void initState() {
    super.initState();
    sign_InOrUp();  // Check the login status when the screen loads
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await SessionManager().remove("id");
    await SessionManager().set("isLoggedIn", false);
    setState(() {
      value = "Sign In";
    });
    Navigator.pushNamed(context, '/login');
  }

  Future<void> _signIn() async {
    Navigator.pushNamed(context, '/login');
  }

  Future<void> sign_InOrUp() async {
    dynamic id = await SessionManager().get("id");
    bool isLoggedIn = await SessionManager().get("isLoggedIn") ?? false;

    if (id == null || !isLoggedIn) {
      setState(() {
        value = "Sign In";
      });
    } else {
      setState(() {
        value = "Sign Out";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF001A2D),
      appBar: AppBar(
        backgroundColor: Color(0xFF001A2D),
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  child: TextButton(
                    onPressed: value=="sign In" ? _signIn : _signOut,
                    child: Row(
                      children: [
                        Icon(Icons.login, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(value),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: TextButton(
                    onPressed: () {
                      // Navigator.pushNamed(context, '/analysis');
                    },
                    child: Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('Analysis'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: TextButton(
                    onPressed: () {
                      // Navigator.pushNamed(context, '/about');
                    },
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('About'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF001A2D), // Very dark blue, almost black
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/');
                },
                icon: Icon(
                  Icons.home,
                  size: 30,
                  color: Colors.white, // White icon color
                ),
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/search');
                },
                icon: Icon(
                  Icons.search,
                  size: 30,
                  color: Colors.white, // White icon color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
