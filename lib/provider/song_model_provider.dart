import 'package:flutter/material.dart';
import 'package:beat_stream/models/FireStoreSongModel.dart'; // Adjust the import as necessary

class SongModelProvider with ChangeNotifier {
  int _id = 0;

  int get id => _id;

  void setId(int id) {
    _id = id;
    notifyListeners();
  }

  FirestoreSongModel? _currentSong;

  void setCurrentSong(FirestoreSongModel song) {
    _currentSong = song;
    notifyListeners();
  }

  FirestoreSongModel? getCurrentSong() {
    return _currentSong;  // Do not force unwrap (!). It might return null.
  }

  bool hasCurrentSong() {
    return _currentSong != null;  // Check if there's a current song
  }
}
