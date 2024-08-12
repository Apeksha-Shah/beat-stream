import 'package:beat_stream/screens/setting_screen.dart';
import 'package:beat_stream/screens/search.dart';

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF001A2D), // Deep dark blue
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Music Player',
                style: TextStyle(color: Colors.white), // White text color
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.notifications_none_rounded,
                color: Colors.white, // White icon color
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> SettingScreen()));
              },
              icon: Icon(
                Icons.settings,
                color: Colors.white, // White icon color
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xFF001A2D), // Very dark blue, almost black
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  margin: EdgeInsets.all(7.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0), // Border radius
                    color: Color(0xFF002B40).withOpacity(0.8), // Dark blue with transparency
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0), // Border radius for image
                        child: Image.asset(
                          'assets/song-2.jpeg',
                          width: 60, // Fixed width for image
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(9.0),
                          child: Text(
                            'Lover',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white, // White text color
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 60,
                  margin: EdgeInsets.all(7.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0), // Border radius
                    color: Color(0xFF002B40).withOpacity(0.8), // Dark blue with transparency
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0), // Border radius for image
                        child: Image.asset(
                          'assets/song-1.jpg',
                          width: 60, // Fixed width for image
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(9.0),
                          child: Text(
                            'Love you zindagi',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white, // White text color
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
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  margin: EdgeInsets.all(7.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0), // Border radius
                    color: Color(0xFF002B40).withOpacity(0.8), // Dark blue with transparency
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0), // Border radius for image
                        child: Image.asset(
                          'assets/song-3.jpg',
                          width: 60, // Fixed width for image
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(9.0),
                          child: Text(
                            'Tere bina',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white, // White text color
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 60,
                  margin: EdgeInsets.all(7.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0), // Border radius
                    color: Color(0xFF002B40).withOpacity(0.8), // Dark blue with transparency
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0), // Border radius for image
                        child: Image.asset(
                          'assets/song-4.jpg',
                          width: 60, // Fixed width for image
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(9.0),
                          child: Text(
                            'I like me better',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white, // White text color
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
        ],
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
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> Search()));

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
