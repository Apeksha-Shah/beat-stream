import 'package:beat_stream/screens/login.dart';
import 'package:beat_stream/screens/registration.dart';
import 'package:beat_stream/screens/search.dart';
import 'package:beat_stream/screens/setting_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       debugShowCheckedModeBanner: false,
        theme: ThemeData(
          appBarTheme: AppBarTheme(
            iconTheme: IconThemeData(
              color: Colors.white, // White icon color
            ),
          )
        ),
        initialRoute: '/login',
        routes: {
           '/':(context)=>HomeScreen(),
           '/setting':(context) => SettingScreen(),
           '/search':(context) => Search(),
           '/login':(context)=> LoginScreen(),
           '/register':(context) => RegisterScreen()
        },
    );
  }
}
