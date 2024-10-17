  import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:just_audio/just_audio.dart';
  import 'package:provider/provider.dart';

  import '../../global/audio_player_singleton.dart';
  import '../../models/FireStoreSongModel.dart';
  import '../../provider/song_model_provider.dart';
  import '../../services/PlaylistService.dart';
  import 'AllSongs.dart';
import 'MusicPlayerWidget.dart';
  import 'Audioplayerscreenstate.dart';

  class PlaylistDetailScreen extends StatefulWidget {
    final String playlistId;

    const PlaylistDetailScreen({Key? key, required this.playlistId}) : super(key: key);

    @override
    _PlaylistDetailScreenState createState() => _PlaylistDetailScreenState();
  }

  class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    int _playingSongIndex = -1;
    List<Map<String, dynamic>> playlistSongs = [];
    bool isPlaying = false;
    String _playlistName = 'Playlist Details';
    @override
    void initState() {
      super.initState();
      fetchPlaylistSongs();

      // Set the current playing song index based on the audio player's current index
      _playingSongIndex = audioPlayer.currentIndex ?? -1;
      //
      // Update _playingSongIndex whenever the current song changes
      audioPlayer.currentIndexStream.listen((index) {
        setState(() {
          _playingSongIndex = index ?? -1;
        });
      });
    }

    Future<void> fetchPlaylistSongs() async {
      try {
        DocumentSnapshot playlistDoc = await _firestore.collection('playlists').doc(widget.playlistId).get();
        if (playlistDoc.exists) {
          // Get playlist name and set the page title
          setState(() {
            _playlistName = playlistDoc.get('name') ?? 'Playlist Details';
          });

          // Fetch song IDs and song details
          List<dynamic> songIds = playlistDoc.get('songIds');
          for (var songId in songIds) {
            DocumentSnapshot songDoc = await _firestore.collection('songs').doc(songId).get();
            if (songDoc.exists) {
              setState(() {
                Map<String, dynamic> songData = songDoc.data() as Map<String, dynamic>;
                songData['id'] = songDoc.id;  // Add the song's document ID to the song data
                playlistSongs.add(songData);
              });
            }
          }

          // Store playlist in the provider
          final songList = playlistSongs.map((e) => FirestoreSongModel.fromMap(e)).toList();
          Provider.of<SongModelProvider>(context, listen: false).setPlaylist(songList);
          Provider.of<SongModelProvider>(context, listen: false).setPlaylistId(widget.playlistId);
        }
      } catch (e) {
        print('Error fetching playlist: $e');
      }
    }

    FirestoreSongModel _mapToSongModel(Map<String, dynamic> song) {
      return FirestoreSongModel(
        id: song['id'] ?? '',
        url: song['Url'] ?? '',
        title: song['songName'] ?? 'Unknown Title',
        artist: song['artist'] ?? 'Unknown Artist',
        album: song['album'] ?? 'Unknown Album',
        genre: song['genre'] ?? 'Unknown Genre',
        releaseDate: DateTime.now(),
        ImageUrl: song['ImageUrl'] ?? 'https://example.com/default_image.png',
        lyrics: song['lyrics'] ?? '',
      );
    }

    Future<void> _playSong(int index) async {
      final song = playlistSongs[index];
      final url = song['Url'] ?? '';

      if (url.isNotEmpty) {
        try {
          // Create an AudioSource
          final audioSource = AudioSource.uri(Uri.parse(url));
          await audioPlayer.setAudioSource(audioSource);
          await audioPlayer.play();

          // Update the provider and state
          final songModelProvider = Provider.of<SongModelProvider>(context, listen: false);
          songModelProvider.setCurrentSong(_mapToSongModel(song));
          setState(() {
            _playingSongIndex = index;
            isPlaying = true;
          });
        } catch (e) {
          print('Error playing song: $e');
        }
      } else {
        print('Error: Song URL is empty or null');
      }
    }



    Future<void> removeSongFromPlaylist(int index) async {
      try {
        final song = playlistSongs[index];
        final songId = song['id'];  // Now the 'id' should not be empty

        if (songId == null || songId.isEmpty) {
          print("Error: songId is empty");
          return;
        }

        print("Removing song with ID: $songId");

        // Call the PlaylistService to remove the song from the playlist in Firestore
        await PlaylistService().removeSongFromPlaylist(widget.playlistId, songId);

        // After removal, update the playlist locally
        setState(() {
          playlistSongs.removeAt(index);
        });

        // Now update Firestore to reflect the changes
        final updatedSongIds = playlistSongs.map((song) => song['id']).toList();

        // Debugging: Print the updated song IDs
        print("Updated song IDs: $updatedSongIds");

        await FirebaseFirestore.instance.collection('playlists')
            .doc(widget.playlistId)
            .update({'songIds': updatedSongIds});

        print("Firestore updated successfully!");
      } catch (e) {
        print("Error removing song: $e");
      }
    }


    @override
    void dispose() {
      // TODO: implement dispose
      super.dispose();
      playlistSongs.clear();
    }
    @override
    Widget build(BuildContext context) {
      final songProvider = Provider.of<SongModelProvider>(context);

      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF001A2D),
          title: Text(_playlistName, style: const TextStyle(color: Colors.white)), // Dynamic title
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Navigate to the "All Songs" screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Allsongs(), // Replace with your actual AllSongsScreen widget
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFF001A2D),
        body: playlistSongs.isEmpty
            ? const Center(
          child: Text(
            'No songs available in this playlist',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        )
            : ListView.builder(
          itemCount: playlistSongs.length,
          itemBuilder: (context, index) {
            final song = playlistSongs[index];
            return ListTile(
              leading: Image.network(
                song['ImageUrl'] ?? 'https://example.com/default_image.png',
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note, color: Colors.white),
              ),
              title: Text(song['songName'] ?? 'Unknown Title', style: const TextStyle(color: Colors.white)),
              subtitle: Text(song['artist'] ?? 'Unknown Artist', style: const TextStyle(color: Colors.white70)),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await removeSongFromPlaylist(index);
                },
              ),
                onTap: () async {
                  setState(() {
                    _playingSongIndex = index;
                  });
                  final clickedSong = _mapToSongModel(playlistSongs[index]);
                  Provider.of<SongModelProvider>(context, listen: false).setCurrentSong(clickedSong);

                  _playSong(_playingSongIndex);  // Error is likely here
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Audioplayerscreenstate(
                        songModel: clickedSong ,  // Error is likely here too
                        audioPlayer: audioPlayer,
                        songList: playlistSongs.map((e) => _mapToSongModel(e)).toList(),
                        currentIndex: index,
                      ),
                    ),
                  );
                }

            );
          },
        ),
        bottomSheet: SafeArea(
          child: SizedBox(
            height: 130,
            child: BottomAppBar(
              color: const Color(0xFF001A2D),
              child: songProvider.hasCurrentSong()
                  ? StreamBuilder<Duration?>(stream: audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final songDuration = audioPlayer.duration ?? Duration.zero;
                    final currentSong = songProvider.getCurrentSong();

                    return MusicPlayerWidget(
                      currentSong: currentSong!,
                      onNext: () async {
                        await songProvider.nextSong();
                      },
                      onPrevious: () async {
                        await songProvider.previousSong();
                      },
                      songPosition: position,
                      songDuration: songDuration,
                    );
                  })
                  : const SizedBox.shrink(), // Return an empty widget if no song is playing
            ),
          ),
        ),
      );
    }
  }
