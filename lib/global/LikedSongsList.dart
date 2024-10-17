// liked_songs.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:beat_stream/models/FireStoreSongModel.dart';
import 'package:beat_stream/global/LikedSongs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beat_stream/provider/song_model_provider.dart'; // Import SongModelProvider if you're using it
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import '../screens/widgets/MusicPlayerWidget.dart'; // Adjust the import based on your project structure
import '../screens/widgets/Audioplayerscreenstate.dart';
import 'audio_player_singleton.dart'; // Adjust the import based on your project structure

class LikedSongs extends StatefulWidget {
  @override
  _LikedSongsState createState() => _LikedSongsState();
}

class _LikedSongsState extends State<LikedSongs> {
  List<FirestoreSongModel> likedSongs = [];
  final LikedSongsService likedSongsService = LikedSongsService();
  TextEditingController _searchController = TextEditingController(); // Search controller
  List<FirestoreSongModel> filteredLikedSongs = []; // List for filtered liked songs
  int _currentSongIndex = -1;

  @override
  void initState() {
    super.initState();
    fetchLikedSongs();
    _searchController.addListener(_filterLikedSongs); // Add listener for search input
  }

  Future<void> fetchLikedSongs() async {
    List<String> likedSongIds = await likedSongsService.getLikedSongs();

    // Ensure likedSongIds contains valid IDs
    if (likedSongIds.isNotEmpty) {
      // Filter out any empty or null IDs
      likedSongIds = likedSongIds.where((id) => id.isNotEmpty).toList();

      if (likedSongIds.isNotEmpty) {
        try {
          // Fetching songs from Firestore based on liked song IDs
          QuerySnapshot snapshot = await FirebaseFirestore.instance
              .collection('songs')
              .where(FieldPath.documentId, whereIn: likedSongIds)
              .get();

          likedSongs = snapshot.docs.map((doc) => FirestoreSongModel.fromDocument(doc)).toList();
          filteredLikedSongs = likedSongs; // Initially, filtered list is the same as liked songs
        } catch (e) {
          print('Error fetching liked songs: $e');
        }
      } else {
        print('No valid liked song IDs found.');
      }
    } else {
      print('No liked song IDs available.');
    }

    setState(() {});
  }


  // Function to filter liked songs based on search input
  Timer? _debounce;
  void _filterLikedSongs() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      setState(() {
        filteredLikedSongs = likedSongs.where((song) =>
        song.title.toLowerCase().contains(query) ||
            song.artist.toLowerCase().contains(query)).toList();
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongModelProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Liked Songs'),
        backgroundColor: Color(0xFF001A2D),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by song name or artist',
                hintStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      backgroundColor: Color(0xFF001A2D), // Set background color
      body: SafeArea(
        child: filteredLikedSongs.isEmpty
            ? Center(child: Text('No liked songs found.', style: TextStyle(color: Colors.white)))
            : ListView.builder(
          itemCount: filteredLikedSongs.length,
          itemBuilder: (context, index) {
            final song = filteredLikedSongs[index];
            return ListTile(
              leading: Image.network(
                song.ImageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.music_note, color: Colors.white); // Fallback icon
                },
              ),
              onTap: () {
                // Handle song tap
                context.read<SongModelProvider>().setCurrentSong(song);
                setState(() {
                  _currentSongIndex = index;
                });
                _playCurrentSong(song);
                // Navigate to the Audioplayerscreenstate if needed
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Audioplayerscreenstate(
                      songModel: song,
                      audioPlayer: audioPlayer, // Ensure this is properly initialized
                      songList: filteredLikedSongs,
                      currentIndex: index,
                    ),
                  ),
                );
              },
              title: Text(
                song.title,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                song.artist,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(
                Icons.more_horiz,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
      bottomSheet: SafeArea(
        child: SizedBox(
          height: 130,
          child: BottomAppBar(
            color: const Color(0xFF001A2D),
            child: songProvider.hasCurrentSong() && audioPlayer.playing
                ? StreamBuilder<Duration?>(
              stream: audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final songDuration = audioPlayer.duration ?? Duration.zero;
                final currentSong = songProvider.getCurrentSong();
                return MusicPlayerWidget(
                  currentSong: currentSong ??
                      FirestoreSongModel(
                        id: '',
                        url: '',
                        title: 'Unknown Song',
                        artist: 'Unknown Artist',
                        album: 'Unknown Album',
                        genre: 'Unknown Genre',
                        releaseDate: DateTime.now(),
                        ImageUrl: '',
                        lyrics: '',
                      ),
                  onNext: () async {
                    await songProvider.nextSong();
                  },
                  onPrevious: () async {
                    await songProvider.previousSong();
                  },
                  songPosition: position,
                  songDuration: songDuration,
                );
              },
            )
                : const SizedBox.shrink(), // Return an empty widget if no song is playing
          ),
        ),
      ),
    );
  }

  void _playCurrentSong(FirestoreSongModel song) async {
    try {
      // Set the audio source and play the song
      final duration = await audioPlayer.setUrl(song.url);
      final mediaItem = MediaItem(
        id: song.url, // Ensure this matches your song model's unique ID
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: duration ?? Duration.zero,
        artUri: Uri.parse(song.ImageUrl), // Song image URL
      );

      await audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.url),
          tag: mediaItem,
        ),
      );

      await audioPlayer.play();
    } catch (e) {
      print("Error playing song: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
