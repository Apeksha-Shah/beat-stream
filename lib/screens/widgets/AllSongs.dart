import 'package:beat_stream/global/audio_player_singleton.dart';
import 'package:beat_stream/screens/widgets/AudioPlayerScreenState.dart';
import 'package:beat_stream/screens/widgets/MusicPlayerWidget.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/song_model_provider.dart';
import '../../models/FireStoreSongModel.dart';

class Allsongs extends StatefulWidget {
  const Allsongs({super.key});

  @override
  State<Allsongs> createState() => _AllsongsState();
}

class _AllsongsState extends State<Allsongs> {
  List<FirestoreSongModel> songs = [];
  List<FirestoreSongModel> filteredSongs = []; // List for filtered songs
  TextEditingController _searchController = TextEditingController(); // Search controller
  int _currentSongIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchSongsFromFirestore();
    _searchController.addListener(_filterSongs); // Add listener for search input
    _currentSongIndex = audioPlayer.currentIndex ?? audioPlayer.androidAudioSessionId ?? -1;
  }

  Future<void> _fetchSongsFromFirestore() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('songs').get();
    final List<FirestoreSongModel> fetchedSongs = snapshot.docs
        .map((doc) => FirestoreSongModel.fromDocument(doc))
        .toList();

    setState(() {
      songs = fetchedSongs;
      filteredSongs = fetchedSongs; // Initially, filtered list is the same as all songs
    });
  }

  // Function to filter songs based on search input
  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredSongs = songs
          .where((song) =>
      song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A2D),
        title: const Text(
          "Music Directory",
          style: TextStyle(color: Colors.white),
        ),
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
              onChanged: (value) {
                _filterSongs(); // Call filter method on text change
              },
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF001A2D),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: filteredSongs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: filteredSongs.length,
                itemBuilder: (context, index) {
                  final song = filteredSongs[index];
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
                      // Set the current song in the provider
                      context.read<SongModelProvider>().setCurrentSong(filteredSongs[index]);

                      // Update the current song index
                      setState(() {
                        _currentSongIndex = index;
                      });

                      // Play the song immediately without waiting for the play button
                      _playCurrentSong();

                      // Navigate to the Audioplayerscreenstate if needed
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Audioplayerscreenstate(
                            songModel: filteredSongs[index],
                            audioPlayer: audioPlayer,
                            songList: filteredSongs,
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
                      '${song.artist}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: SizedBox(
                height: 130,
                child: BottomAppBar(
                  color: const Color(0xFF001A2D),
                  child: songs.isNotEmpty && _currentSongIndex != -1
                      ? StreamBuilder<Duration?>(
                    stream: audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final songDuration = audioPlayer.duration ?? Duration.zero;

                      return MusicPlayerWidget(
                        currentSong: context.read<SongModelProvider>().getCurrentSong() ??
                            FirestoreSongModel(
                              id: '', // Default or placeholder ID
                              url: '',
                              title: 'Unknown Song',
                              artist: 'Unknown Artist',
                              album: 'Unknown Album',
                              genre: 'Unknown Genre',
                              releaseDate: DateTime.now(),
                              ImageUrl: '',
                              lyrics: '',
                            ),
                        onNext: _nextSong,
                        onPrevious: _previousSong,
                        songPosition: position,
                        songDuration: songDuration,
                      );
                    },
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _nextSong() {
    if (_currentSongIndex < songs.length - 1) {
      setState(() {
        _currentSongIndex++;
      });
      context.read<SongModelProvider>().setCurrentSong(songs[_currentSongIndex]);
      _playCurrentSong();
    }
  }

  void _previousSong() {
    if (_currentSongIndex > 0) {
      setState(() {
        _currentSongIndex--;
      });
      context.read<SongModelProvider>().setCurrentSong(songs[_currentSongIndex]);
      _playCurrentSong();
    }
  }

  void _playCurrentSong() async {
    try {
      final song = songs[_currentSongIndex];

      // Get actual duration before setting the audio source
      final duration = await audioPlayer.setUrl(song.url);

      final mediaItem = MediaItem(
        id: song.url, // Ensure this matches your song model's unique ID
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: duration ?? Duration.zero, // Use fetched duration
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
