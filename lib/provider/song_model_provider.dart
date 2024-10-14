import 'package:flutter/material.dart';
import 'package:beat_stream/models/FireStoreSongModel.dart'; // Adjust the import as necessary

class SongModelProvider with ChangeNotifier {
  String _id = '';
  FirestoreSongModel? _currentSong;

  // Getter for the current song ID
  String get id => _id;

  // Setter for the current song ID with notification
  void setId(String id) {
    _id = id;
    notifyListeners(); // Notify listeners that the song ID has changed
  }

  // Getter for the current song
  FirestoreSongModel? getCurrentSong() {
    return _currentSong;  // Return the current song or null if not set
  }

  // Setter for the current song with notification
  void setCurrentSong(FirestoreSongModel song) {
    _currentSong = song;
    notifyListeners(); // Notify listeners that the current song has changed
  }

  // Check if there's a current song set
  bool hasCurrentSong() {
    return _currentSong != null;  // Return true if a song is set, false otherwise
  }
}
