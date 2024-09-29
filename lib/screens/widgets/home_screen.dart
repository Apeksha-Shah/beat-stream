import 'package:beat_stream/screens/widgets/MusicPlayerWidget.dart';
import 'package:flutter/material.dart';
import 'package:beat_stream/screens/widgets/song_carousel.dart';
import 'package:beat_stream/models/song.dart';
import 'package:beat_stream/global/audio_player_singleton.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../provider/song_model_provider.dart'; // Import your provider

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Song> songs = [
    Song(imagePath: 'assets/song-2.jpeg', title: 'Lover'),
    Song(imagePath: 'assets/song-1.jpg', title: 'Love you zindagi'),
    Song(imagePath: 'assets/song-3.jpg', title: 'Tere bina'),
    Song(imagePath: 'assets/song-4.jpg', title: 'I like me better'),
  ];

  List<SongModel> deviceSongs = []; // To store songs from the device
  final OnAudioQuery _audioQuery = OnAudioQuery(); // Initialize OnAudioQuery
  int _currentSongIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchDeviceSongs();
    _currentSongIndex =  audioPlayer.androidAudioSessionId ?? 0;
  }

  Future<void> fetchDeviceSongs() async {
    // Request storage permissions and fetch songs from the device
    var permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      await _audioQuery.permissionsRequest();
    }

    // Fetch songs from the device and store them
    deviceSongs = await _audioQuery.querySongs();
    setState(() {});
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
            Column(
              children: List.generate(
                (songs.length / 2).ceil(),
                    (index) {
                  int startIndex = index * 2;
                  int endIndex = (startIndex + 2) > songs.length ? songs.length : startIndex + 2;
                  return Row(
                    children: List.generate(
                      endIndex - startIndex,
                          (i) {
                        final song = songs[startIndex + i];
                        return Expanded(
                          child: Container(
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
                                  child: Image.asset(
                                    song.imagePath,
                                    width: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(9.0),
                                    child: Text(
                                      song.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            SongCarousel(songs: deviceSongs, title: 'Top Mixes'),
            const SizedBox(height: 40),
            SongCarousel(
              songs: deviceSongs,
              title: 'Recently Played',
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 200,
        child: BottomAppBar(
          color: Color(0xFF001A2D),
          child: Column(
            children: [
              SafeArea(
                child: SizedBox(
                  height: 120,
                  child:   deviceSongs.isNotEmpty && _currentSongIndex !=0
                      ?StreamBuilder<Duration?>(
                    stream: audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final songDuration = audioPlayer.duration ?? Duration.zero;

                      return MusicPlayerWidget(
                        currentSong: context.read<SongModelProvider>().getCurrentSong(),
                        onNext: _nextSong,
                        onPrevious: _previousSong,
                        songPosition: position,
                        songDuration: songDuration,
                      );
                    },
                  ):  const SizedBox.shrink(),
                ),
              ),
              Row(
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
              ),
            ],
          ),
        ),
      ),
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
    final song = deviceSongs[_currentSongIndex];

    // Create a MediaItem with the song's metadata
    final mediaItem = MediaItem(
      id: song.uri!,
      album: song.album ?? "Unknown Album",
      title: song.displayNameWOExt,
      artist: song.artist ?? "Unknown Artist",
      duration: Duration(milliseconds: song.duration ?? 0),
      artUri: Uri.parse(song.uri!),
    );

    // Set the audio source with the media item as a tag
    await audioPlayer.setAudioSource(
      AudioSource.uri(
        Uri.parse(song.uri!),
        tag: mediaItem,
      ),
    );

    // Play the song
    await audioPlayer.play();
  }
}
