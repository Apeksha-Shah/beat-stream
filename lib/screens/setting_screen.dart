import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  SettingScreen();
  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF001A2D),
       appBar: AppBar(
           backgroundColor: Color(0xFF001A2D),
         title: Text('Settings',
         style: TextStyle(
           color: Colors.white
         )),
       ),
      body: Center(
         child: Text('Body of setting page',
         style: TextStyle(
           color: Colors.white,     // Deep dark blue
         ),
         ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF001A2D), // Very dark blue, almost black
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () {},
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
