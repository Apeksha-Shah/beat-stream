import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          appBarTheme: AppBarTheme(
            iconTheme: IconThemeData(
              color: Colors.white, // White icon color
            ),
          )
        ),
        home: HomeScreen()
    );
  }
}
