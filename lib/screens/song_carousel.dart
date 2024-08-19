import 'package:flutter/material.dart';
import 'package:beat_stream/models/song.dart';

// SongCarousel widget
class SongCarousel extends StatelessWidget {
  final List<Song> songs;
  final String title;

  SongCarousel({required this.songs, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 10), // Space between label and carousel
        Container(
          height: 150, // Adjust height as needed
          color: Color(0xFF002B40).withOpacity(0.8), // Dark blue with transparency
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Container(
                width: 120, // Adjust width as needed
                margin: EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        song.imagePath,
                        width: 120, // Width of the image
                        height: 120, // Height of the image
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
