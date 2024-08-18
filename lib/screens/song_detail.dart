import 'package:flutter/material.dart';

class SongDetailScreen extends StatelessWidget {
  final dynamic song;

  SongDetailScreen({required this.song});

  @override
  Widget build(BuildContext context) {
    var songName = song['name'];
    var artistName = song['artists'][0]['name'];
    var albumName = song['album']['name'];
    var albumArtUrl = song['album']['images'][0]['url'];

    return Scaffold(
      appBar: AppBar(
        title: Text(songName),
        backgroundColor: Color(0xFF001A2D),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              albumArtUrl,
              fit: BoxFit.cover,
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.error, size: 100, color: Colors.white);
              },
            ),
            SizedBox(height: 16.0),
            Text(
              songName,
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 8.0),
            Text(
              '$artistName - $albumName',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
