import 'package:beat_stream/global/audio_player_singleton.dart';
import 'package:beat_stream/screens/widgets/AudioPlayerScreenState.dart';
import 'package:beat_stream/screens/widgets/MusicPlayerWidget.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../provider/song_model_provider.dart';

class Allsongs extends StatefulWidget {
  const Allsongs({super.key});

  @override
  State<Allsongs> createState() => _AllsongsState();
}

class _AllsongsState extends State<Allsongs> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel>? songs; // State variable to hold the list of songs
  int _currentSongIndex = 0; // Variable to track the current song index

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _currentSongIndex = audioPlayer.androidAudioSessionId ?? 0;
  }

  Future<void> _requestPermission() async {
    if (!await Permission.storage.request().isGranted) {
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A2D),
        title: const Text(
          "Local Music Directory",
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
              child: FutureBuilder<List<SongModel>>(
                future: _audioQuery.querySongs(
                  sortType: null,
                  orderType: OrderType.ASC_OR_SMALLER,
                  uriType: UriType.EXTERNAL,
                  ignoreCase: true,
                ),
                builder: (context, item) {
                  if (item.data == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (item.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "No song found",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  // Save the fetched songs to the state variable
                  songs = item.data;

                  // Reset current song index if it exceeds the number of songs
                  if (_currentSongIndex >= songs!.length) {
                    _currentSongIndex = 0;
                  }

                  return ListView.builder(
                    itemCount: songs!.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: QueryArtworkWidget(
                        id: songs![index].id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: const Icon(Icons.music_note),
                      ),
                      onTap: () {
                        context.read<SongModelProvider>().setCurrentSong(songs![index]); // Set current song
                        setState(() {
                          _currentSongIndex = index; // Update current song index
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Audioplayerscreenstate(
                              songModel: songs![index],
                              audioPlayer: audioPlayer,
                              songList: songs!,
                              currentIndex: index,
                            ),
                          ),
                        );
                      },
                      title: Text(
                        songs![index].displayNameWOExt,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        songs![index].artist ?? "Unknown Artist",
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                      ),
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
                  child: songs != null && songs!.isNotEmpty && _currentSongIndex !=0 && audioPlayer.androidAudioSessionId != 0
                      ? StreamBuilder<Duration?>(
                    stream: audioPlayer.positionStream, // Listen to the player's position
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final songDuration = audioPlayer.duration ?? Duration.zero;

                      return MusicPlayerWidget(
                        currentSong: context.read<SongModelProvider>().getCurrentSong(),
                        onNext: _nextSong,
                        onPrevious: _previousSong,
                        songPosition: position, // Pass the current song position to the widget
                        songDuration: songDuration, // Pass the song duration to the widget
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
    if (songs != null && _currentSongIndex < songs!.length - 1) {
      setState(() {
        _currentSongIndex++;
      });
      context.read<SongModelProvider>().setCurrentSong(songs![_currentSongIndex]); // Track the current song
      _playCurrentSong();
    }
  }

  void _previousSong() {
    if (songs != null && _currentSongIndex > 0) {
      setState(() {
        _currentSongIndex--;
      });
      context.read<SongModelProvider>().setCurrentSong(songs![_currentSongIndex]); // Track the current song
      _playCurrentSong();
    }
  }
  void _playCurrentSong() async {
    final song = songs![_currentSongIndex];

    // Create a MediaItem with the song's metadata
    final mediaItem = MediaItem(
      id: song.uri!, // Use the song's URI as the ID
      album: song.album ?? "Unknown Album",
      title: song.displayNameWOExt, // Song title without extension
      artist: song.artist ?? "Unknown Artist",
      duration: Duration(milliseconds: song.duration ?? 0), // Duration of the song
      artUri: Uri.parse(song.uri!), // You can adjust this if you have artwork
    );

    // Set the audio source with the media item as a tag
    await audioPlayer.setAudioSource(
      AudioSource.uri(
        Uri.parse(song.uri!), // Song URI
        tag: mediaItem, // MediaItem with metadata
      ),
    );

    // Play the song
    await audioPlayer.play();
  }

}
