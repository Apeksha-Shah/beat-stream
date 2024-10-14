import 'package:shared_preferences/shared_preferences.dart';

class LikedSongsService {
  static const String _likedSongsKey = 'likedSongs';

  Future<void> saveLikedSong(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final likedSongs = prefs.getStringList(_likedSongsKey) ?? [];
    if (!likedSongs.contains(songId)) {
      likedSongs.add(songId);
      await prefs.setStringList(_likedSongsKey, likedSongs);
    }
  }

  Future<void> removeLikedSong(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final likedSongs = prefs.getStringList(_likedSongsKey) ?? [];
    likedSongs.remove(songId);
    await prefs.setStringList(_likedSongsKey, likedSongs);
  }

  Future<List<String>> getLikedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_likedSongsKey) ?? [];
  }
}
