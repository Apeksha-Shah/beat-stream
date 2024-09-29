import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:beat_stream/models/FireStoreSongModel.dart'; // Ensure this is the correct import for FirestoreSongModel
import 'package:beat_stream/screens/widgets/MusicPlayerWidget.dart';
import 'package:beat_stream/screens/widgets/song_carousel.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../global/audio_player_singleton.dart';
import '../../provider/song_model_provider.dart'; // Import your provider
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FirestoreSongModel> deviceSongs = [];
  final OnAudioQuery _audioQuery = OnAudioQuery();
  int _currentSongIndex = 0;
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    fetchDeviceSongs();
  }

  Future<void> fetchDeviceSongs() async {
    // Request storage permissions
    var permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      await _audioQuery.permissionsRequest();
    }

    // Fetch songs from Firestore
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('songs').get();
      deviceSongs = snapshot.docs.map((doc) => FirestoreSongModel.fromDocument(doc)).toList();
      setState(() {});
    } catch (e) {
      print("Error fetching songs: $e"); // Handle errors gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF001A2D),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Music Player',
                style: TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.notifications_none_rounded, color: Colors.white),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/setting');
              },
              icon: Icon(Icons.settings, color: Colors.white),
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xFF001A2D),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/Allsongs');
                  },
                  child: const Icon(Icons.storage, color: Colors.white),
                ),
              ),
            ),
            buildSongRows(), // Build the song rows dynamically
            const SizedBox(height: 40),
            SongCarousel(songs: deviceSongs, title: 'Top Mixes'),
            const SizedBox(height: 40),
            SongCarousel(songs: deviceSongs, title: 'Recently Played'),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomAppBar(),
    );
  }

  Widget buildSongRows() {
    return Column(
      children: List.generate(
        (deviceSongs.length / 2).ceil(),
            (index) {
          int startIndex = index * 2;
          int endIndex = (startIndex + 2) > deviceSongs.length ? deviceSongs.length : startIndex + 2;
          return Row(
            children: List.generate(
              endIndex - startIndex,
                  (i) {
                final song = deviceSongs[startIndex + i];
                return Expanded(
                  child: buildSongTile(song),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Updated: set a default image without accessing FirestoreSongModel imageUrl
  Widget buildSongTile(FirestoreSongModel song) {
    const String defaultImageUrl = 'https://via.placeholder.com/150'; // Default image

    return Container(
      height: 60,
      margin: EdgeInsets.all(7.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Color(0xFF002B40).withOpacity(0.8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              defaultImageUrl, // Always use default image
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.music_note, color: Colors.white); // Fallback if the image fails
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(9.0),
              child: Text(
                song.title,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomAppBar() {
    return SizedBox(
      height: 200,
      child: BottomAppBar(
        color: Color(0xFF001A2D),
        child: Column(
          children: [
            SafeArea(
              child: SizedBox(
                height: 120,
                child: deviceSongs.isNotEmpty && context.read<SongModelProvider>().hasCurrentSong()
                    ? StreamBuilder<Duration?>( // Stream to listen to the audio position
                  stream: audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final songDuration = audioPlayer.duration ?? Duration.zero;

                    return MusicPlayerWidget(
                      currentSong: context.read<SongModelProvider>().getCurrentSong()!,
                      onNext: _nextSong,
                      onPrevious: _previousSong,
                      songPosition: position,
                      songDuration: songDuration,
                    );
                  },
                )
                    : const SizedBox.shrink(), // Handle no song case
              ),
            ),
            buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.home, size: 30, color: Colors.white),
          ),
        ),
        Expanded(
          child: IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
            icon: const Icon(Icons.search, size: 30, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _nextSong() {
    if (_currentSongIndex < deviceSongs.length - 1) {
      setState(() {
        _currentSongIndex++;
      });
      context.read<SongModelProvider>().setCurrentSong(deviceSongs[_currentSongIndex]);
      _playCurrentSong();
    }
  }

  void _previousSong() {
    if (_currentSongIndex > 0) {
      setState(() {
        _currentSongIndex--;
      });
      context.read<SongModelProvider>().setCurrentSong(deviceSongs[_currentSongIndex]);
      _playCurrentSong();
    }
  }

  void _playCurrentSong() async {
    FirestoreSongModel currentSong = deviceSongs[_currentSongIndex];
    try {
      await audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(currentSong.url),
          tag: MediaItem(
            id: currentSong.id,
            album: currentSong.album ?? 'Unknown Album',
            title: currentSong.title,
            artUri: Uri.parse('https://via.placeholder.com/150'), // Default image
          ),
        ),
      );
      audioPlayer.play();
    } catch (e) {
      print("Error playing song: $e"); // Handle any errors during playback
    }
  }
}
