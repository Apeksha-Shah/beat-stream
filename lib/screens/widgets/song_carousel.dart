import 'package:beat_stream/screens/widgets/ArtWorkWidget.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:beat_stream/screens/widgets/AudioPlayerScreenState.dart';

import 'AudioPlayerScreenState.dart';


class SongCarousel extends StatefulWidget {
  final List<SongModel> songs; // Use SongModel from on_audio_query package
  final String title;

  SongCarousel({required this.songs, required this.title});

  @override
  State<SongCarousel> createState() => _SongCarouselState();
}

class _SongCarouselState extends State<SongCarousel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            widget.title,
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
            itemCount: widget.songs.length,
            itemBuilder: (context, index) {
              final song = widget.songs[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Audioplayerscreenstate(
                        songModel: song,
                        audioPlayer: AudioPlayer(),
                        songList: widget.songs,
                        currentIndex: index,

                      ),
                    ),
                  );
                },
                child: Container(
                  width: 120, // Adjust width as needed
                  margin: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: QueryArtworkWidget(                    //ArtWorkWidget()
                          // Display album artwork using QueryArtworkWidget
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          nullArtworkWidget: Icon(
                            Icons.music_note,
                            size: 110,
                            color: Colors.white70,
                          ),
                          artworkFit: BoxFit.cover,
                          artworkBorder: BorderRadius.circular(8.0),
                          artworkWidth: 120,
                          artworkHeight: 120,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        song.title, // Use song.title from SongModel
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, // Prevent text overflow
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
