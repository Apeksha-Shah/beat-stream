import 'package:beat_stream/provider/song_model_provider.dart';
import 'package:beat_stream/screens/widgets/AllSongs.dart';
import 'package:beat_stream/screens/widgets/login.dart';
import 'package:beat_stream/screens/widgets/registration.dart';
import 'package:beat_stream/screens/widgets/search.dart';
import 'package:beat_stream/screens/widgets/setting_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'global/LikedSongsList.dart';
import 'screens/widgets/home_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDhafLRqeh4ICeof72jkajsOPUrfRoG5eU",
        appId: "1:913733783503:web:ae24550a1ec6138cd60cba",
        messagingSenderId: "913733783503",
        projectId: "beat-stream-4390a",
      ),
    );
  } else {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
  }

  runApp(ChangeNotifierProvider(
    create: (context) => SongModelProvider(),
    child: App(),
  ));
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    // Delay permission request
    Future.delayed(Duration.zero, () {
      requestPermissions();
    });
  }

  Future<void> requestPermissions() async {
    var status = await Permission.storage.status;

    if (status.isDenied) {
      // Request storage permission
      await Permission.storage.request();
    }

    // After requesting, check again
    if (await Permission.storage.isGranted) {
      // Permission is granted, you can proceed
      print("Storage permission granted");
    } else {
      // If permission is still denied, you can prompt to open app settings
      bool isOpened = await openAppSettings();
      if (!isOpened) {
        print('Failed to open app settings');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(
            color: Colors.white, // White icon color
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/': (context) => HomeScreen(),
        '/setting': (context) => SettingScreen(),
        '/search': (context) => Search(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/Allsongs': (context) => const Allsongs(),
        '/liked_songs': (context) => LikedSongs(),
      },
    );
  }
}
