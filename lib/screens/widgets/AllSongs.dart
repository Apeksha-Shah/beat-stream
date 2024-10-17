import 'dart:async';
import 'package:beat_stream/global/audio_player_singleton.dart';
import 'package:beat_stream/screens/widgets/AudioPlayerScreenState.dart';
import 'package:beat_stream/screens/widgets/MusicPlayerWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:beat_stream/screens/widgets/playlistpage.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../global/toast.dart';
import '../../provider/song_model_provider.dart';
import '../../models/FireStoreSongModel.dart';

class Allsongs extends StatefulWidget {
  const Allsongs({super.key});

  @override
  State<Allsongs> createState() => _AllsongsState();
}

class _AllsongsState extends State<Allsongs> {
  List<FirestoreSongModel> songs = [];
  List<FirestoreSongModel> filteredSongs = [];
  TextEditingController _searchController = TextEditingController();
  int _currentSongIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchSongsFromFirestore();
    _searchController.addListener(_filterSongs);
    _currentSongIndex = audioPlayer.currentIndex ?? audioPlayer.androidAudioSessionId ?? -1;
  }

  Future<void> _fetchSongsFromFirestore() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('songs').get();
    final List<FirestoreSongModel> fetchedSongs = snapshot.docs
        .map((doc) => FirestoreSongModel.fromDocument(doc))
        .toList();

    setState(() {
      songs = fetchedSongs;
      filteredSongs = fetchedSongs;
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

  void _addToPlaylist(FirestoreSongModel song) async {
    var userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      showToast(message: "User not logged in!");
      return;
    }

    try {
      // Fetch the playlists that belong to the logged-in user
      var playlistsSnapshot = await FirebaseFirestore.instance
          .collection('playlists')
          .where('userId', isEqualTo: userId) // Filter by userId
          .get();

      // Show dialog for the user to either create a new playlist or select an existing one
      if (playlistsSnapshot.docs.isEmpty) {
        // If there are no playlists, show a message and prompt the user to create a new one
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("No Playlists Available"),
              content: const Text("You have no playlists. Would you like to create a new one?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _createNewPlaylist(userId, song.id); // Create new playlist
                  },
                  child: const Text("Create New Playlist"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog if the user doesn't want to create one
                  },
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      } else {
        // If playlists exist, show the dialog with existing playlists
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Add to Playlist"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show existing playlists
                  ...playlistsSnapshot.docs.map((playlist) {
                    return ListTile(
                      title: Text(playlist['name']),
                      onTap: () async {
                        // Add the song to the selected playlist
                        await _addToExistingPlaylist(playlist.id, song.id);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  // Create a new playlist option
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _createNewPlaylist(userId, song.id);
                    },
                    child: const Text("Create New Playlist"),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      showToast(message: "Error loading playlists: $e");
    }
  }


  Future<void> _addToExistingPlaylist(String playlistId, String songId) async {
    try {
      await FirebaseFirestore.instance
          .collection('playlists')
          .doc(playlistId)
          .update({
        'songIds': FieldValue.arrayUnion([songId]) // Add the song to the playlist
      });

      showToast(message: "Song added to playlist!");
    } catch (e) {
      showToast(message: "Error adding song to playlist: $e");
    }
  }
  void _createNewPlaylist(String userId, String songId) async {
    String playlistName = await showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text("Enter Playlist Name"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter name for new playlist",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (playlistName.isNotEmpty) {
      try {
        // Create a new playlist and add the song to it
        await FirebaseFirestore.instance.collection('playlists').add({
          'name': playlistName,
          'userId': userId,
          'songIds': [songId], // Add the current song to the new playlist
        });

        showToast(message: "New playlist '$playlistName' created and song added!");
      } catch (e) {
        showToast(message: "Error creating playlist: $e");
      }
    } else {
      showToast(message: "Playlist name cannot be empty!");
    }
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
            icon: const Icon(
                Icons.library_music,
                size: 25.0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlaylistPage()),
              );
            },
          ),
          const SizedBox(width: 30.0,)
        ],
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
                _filterSongs();
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
                        return const Icon(Icons.music_note, color: Colors.white);
                      },
                    ),
                    onTap: () {
                      context.read<SongModelProvider>().setCurrentSong(filteredSongs[index]);
                      setState(() {
                        _currentSongIndex = index;
                      });
                      _playCurrentSong();
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
                    trailing: IconButton(
                      icon: const Icon(Icons.playlist_add, color: Colors.white),
                      onPressed: () {
                        _addToPlaylist(song); // Trigger the playlist dialog
                      },
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
                  child: (songs.isNotEmpty && _currentSongIndex != -1) || audioPlayer.playing
                      ? StreamBuilder<Duration?>(
                    stream: audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final songDuration = audioPlayer.duration ?? Duration.zero;
                      return MusicPlayerWidget(
                        currentSong: context.read<SongModelProvider>().getCurrentSong() ??
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
      final duration = await audioPlayer.setUrl(song.url);
      final mediaItem = MediaItem(
        id: song.url,
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: duration ?? Duration.zero,
        artUri: Uri.parse(song.ImageUrl),
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