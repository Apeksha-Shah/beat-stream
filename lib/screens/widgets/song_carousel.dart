import 'package:beat_stream/global/audio_player_singleton.dart';
import 'package:beat_stream/screens/widgets/ArtWorkWidget.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:beat_stream/screens/widgets/AudioPlayerScreenState.dart';
import 'package:provider/provider.dart';
import '../../models/FireStoreSongModel.dart';
import '../../provider/song_model_provider.dart';

class SongCarousel extends StatefulWidget {
  final List<FirestoreSongModel> songs; // Updated type
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
                  context.read<SongModelProvider>().setCurrentSong(widget.songs[index]);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Audioplayerscreenstate(
                        songModel: song, // Updated type
                        audioPlayer: audioPlayer,
                        songList: widget.songs, // Pass the same list
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
                        child:song.ImageUrl != null && song.ImageUrl.isNotEmpty
                            ? Image.network(
                          song.ImageUrl, // Use image URL from Firestore
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                            : QueryArtworkWidget(
                          // Display album artwork using QueryArtworkWidget
                          id: int.tryParse(song.id) ?? 0, // Assuming song.id is still valid
                          type: ArtworkType.AUDIO,
                          nullArtworkWidget: Image.network(
                            'https://via.placeholder.com/150', // Fallback/default image URL
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ), // Use Image.network as a fallback image
                          artworkFit: BoxFit.cover,
                          artworkBorder: BorderRadius.circular(8.0),
                          artworkWidth: 120,
                          artworkHeight: 120,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        song.title, // Use song.title from FirestoreSongModel
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
