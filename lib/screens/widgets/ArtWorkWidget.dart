import 'package:beat_stream/models/FireStoreSongModel.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../provider/song_model_provider.dart';

class ArtWorkWidget extends StatelessWidget {
  final FirestoreSongModel song;
  const ArtWorkWidget({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show lyrics when artwork is clicked
        showLyricsDialog(context, song);
      },
      child: song.ImageUrl.isNotEmpty
          ? Image.network(
        song.ImageUrl, // Use image URL from Firestore
        width: 350,
        height: 350,
        fit: BoxFit.cover,
      )
          : QueryArtworkWidget(
        // Display album artwork using QueryArtworkWidget
        id: int.tryParse(song.id) ?? 0, // Assuming song.id is still valid
        type: ArtworkType.AUDIO,
        nullArtworkWidget: Image.network(
          'https://via.placeholder.com/150', // Fallback/default image URL
          width: 300,
          height: 300,
          fit: BoxFit.cover,
        ), // Use Image.network as a fallback image
        artworkFit: BoxFit.cover,
        artworkBorder: BorderRadius.circular(8.0),
        artworkWidth: 300,
        artworkHeight: 300,
      ),
    );
  }

  // Function to show lyrics in a dialog
  void showLyricsDialog(BuildContext context, FirestoreSongModel song) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            song.title,
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Text(
              song.lyrics, // Assuming lyrics are stored in the `FirestoreSongModel`
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Close',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
