import 'package:flutter/material.dart';
import 'package:beat_stream/screens/song_carousel.dart';
import 'package:beat_stream/models/song.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Song> songs = [
    Song(imagePath: 'assets/song-2.jpeg', title: 'Lover'),
    Song(imagePath: 'assets/song-1.jpg', title: 'Love you zindagi'),
    Song(imagePath: 'assets/song-3.jpg', title: 'Tere bina'),
    Song(imagePath: 'assets/song-4.jpg', title: 'I like me better'),
  ];

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
                Navigator.pushNamed(context, '/setting');
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
      body:SingleChildScrollView(
        child:Column(
          children: [
          Column(
            children: List.generate(
            (songs.length / 2).ceil(),
              (index) {
            int startIndex = index * 2;
            int endIndex = (startIndex + 2) > songs.length ? songs.length : startIndex + 2;
            return Row(
              children: List.generate(
                endIndex - startIndex,
                    (i) {
                  final song = songs[startIndex + i];
                  return Expanded(
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
                              song.imagePath,
                              width: 60, // Fixed width for image
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(9.0),
                              child: Text(
                                song.title,
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
                  );
                },
              ),
            );
          },
        ),
      ),
            SizedBox(height: 40), // Add space between the list and the carousel
            SongCarousel(songs: songs, title: 'Top Mixes'),   // Carousel
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


