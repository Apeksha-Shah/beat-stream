import 'package:flutter/material.dart';
import 'package:on_audio_query_platform_interface/src/models/song_model.dart';

class SongModelProvider with ChangeNotifier {
  int _id = 0;

  int get id => _id;

  void setId(int id) {
    _id = id;
    notifyListeners();
  }
  SongModel? _currentSong;

  void setCurrentSong(SongModel song) {
    _currentSong = song;
    notifyListeners();
  }

  SongModel getCurrentSong() {
    return _currentSong!;
  }
}