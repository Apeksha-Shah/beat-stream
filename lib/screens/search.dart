import 'package:flutter/material.dart';

class Search extends StatefulWidget {
  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF001A2D), // Very dark blue background
      appBar: AppBar(
        backgroundColor: Color(0xFF001A2D), // AppBar background color
        title: Text(
          'Search',
          style: TextStyle(
            color: Colors.white, // AppBar title text color
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(12.0), // Add padding for better layout
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search song or artist', // Placeholder text
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6), // Light color for hint text
                ),
                filled: true,
                fillColor: Color(0xFF002B40), // Dark blue background for the TextField
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0), // Rounded corners
                  borderSide: BorderSide.none, // No border line
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 18.0), // Padding inside the TextField
              ),
              style: TextStyle(
                color: Colors.white, // Text color inside the TextField
              ),
            ),
          ],
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
