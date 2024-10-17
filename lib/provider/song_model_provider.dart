import 'package:flutter/material.dart';
import 'package:beat_stream/models/FireStoreSongModel.dart';
import '../global/audio_player_singleton.dart'; // Adjust the import as necessary

class SongModelProvider with ChangeNotifier {
  String _id = '';
  FirestoreSongModel? _currentSong;

  // Variables for playlist management
  String? _playlistId;
  List<FirestoreSongModel> _playlist = [];

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

  List<Map<String, dynamic>> _playlistSongs = [];
  int _playingSongIndex = -1;
  int get playingSongIndex => _playingSongIndex;
  List<Map<String, dynamic>> get playlistSongs => _playlistSongs;

  // Load songs into the playlist
  void loadPlaylist(List<Map<String, dynamic>> songs) {
    _playlistSongs = songs;
    _playingSongIndex = -1;  // Reset the playing song index when a new playlist is loaded
    _currentSong = null;  // Reset the current song when a new playlist is loaded
    notifyListeners();
  }

  // Play song by index
  Future<void> playSong(int index) async {
    if (index >= 0 && index < _playlistSongs.length) {
      final song = _playlistSongs[index];
      await audioPlayer.setUrl(song['Url']);
      await audioPlayer.play();

      _playingSongIndex = index;
      _currentSong = FirestoreSongModel(
        id: song['id'],
        url: song['Url'],
        title: song['songName'],
        artist: song['artist'],
        album: song['album'],
        genre: song['genre'],
        releaseDate: DateTime.now(),
        ImageUrl: song['ImageUrl'] ?? 'https://example.com/default_image.png',
        lyrics: song['lyrics'],
      );
      notifyListeners();
    }
  }

  // Play next song
  Future<void> nextSong() async {
    if (_playingSongIndex < _playlistSongs.length - 1) {
      await playSong(_playingSongIndex + 1);
    }
    notifyListeners();
  }

  // Play previous song
  Future<void> previousSong() async {
    if (_playingSongIndex > 0) {
      await playSong(_playingSongIndex - 1);
    }
    notifyListeners();
  }

  // Stop playback
  Future<void> stopPlayback() async {
    await audioPlayer.stop();
    _playingSongIndex = -1;
    _currentSong = null;
    notifyListeners();
  }

  // Set playlist
  void setPlaylist(List<FirestoreSongModel> playlist) {
    _playlist = playlist;
    _playlistSongs = playlist.map((song) => {
      'id': song.id,
      'Url': song.url,
      'songName': song.title,
      'artist': song.artist,
      'album': song.album,
      'genre': song.genre,
      'ImageUrl': song.ImageUrl,
      'lyrics': song.lyrics,
    }).toList();
    _playingSongIndex = -1;  // Reset the playing song index when the playlist changes
    _currentSong = null;  // Reset the current song when the playlist changes
    notifyListeners();
  }

  // Set playlist ID
  void setPlaylistId(String playlistId) {
    _playlistId = playlistId;
    notifyListeners();
  }

  // Getter for playlist ID
  String? get playlistId => _playlistId;

  // Getter for playlist
  List<FirestoreSongModel> get playlist => _playlist;
}
