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
  int _currentSongIndex = -1; // Start from -1 to handle no selection scenario

  @override
  void initState() {
    super.initState();
    _fetchSongsFromFirestore();
  }

  Future<void> _fetchSongsFromFirestore() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('songs').get();
    final List<FirestoreSongModel> fetchedSongs = snapshot.docs
        .map((doc) => FirestoreSongModel.fromDocument(doc))
        .toList();

    setState(() {
      songs = fetchedSongs;
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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/Audioplayerscreenstate');
            },
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF001A2D),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: songs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
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
                      context.read<SongModelProvider>().setCurrentSong(songs[index]);

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
                            songModel: songs[index],
                            audioPlayer: audioPlayer,
                            songList: songs,
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
                              genre: 'Unknown Genre', // Default or placeholder genre
                              releaseDate: DateTime.now(), // Default or placeholder release date
                              ImageUrl: '',
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
  }
}
