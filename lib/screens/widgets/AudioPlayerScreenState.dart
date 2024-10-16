import 'dart:developer';
import 'package:beat_stream/global/toast.dart';
import 'package:beat_stream/screens/widgets/ArtWorkWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:beat_stream/global/audio_player_singleton.dart';
import 'package:provider/provider.dart';
import '../../controller/MusicPlayerControls.dart';
import '../../provider/song_model_provider.dart';
import '../../models/FireStoreSongModel.dart';
import '../../global/LikedSongs.dart'; // Import the service at the top

class Audioplayerscreenstate extends StatefulWidget {
  const Audioplayerscreenstate({
    super.key,
    required this.songModel,
    required this.audioPlayer,
    required this.songList,
    required this.currentIndex,
  });

  final FirestoreSongModel songModel; // Updated type
  final AudioPlayer audioPlayer;
  final List<FirestoreSongModel> songList; // Updated type
  final int currentIndex;

  @override
  State<Audioplayerscreenstate> createState() => _AudioplayerscreenstateState();
}

class _AudioplayerscreenstateState extends State<Audioplayerscreenstate> {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _songDuration = Duration.zero;
  int _currentSongIndex = 0;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  bool _isMounted = false;
  Set<String> likedSongs = {}; // Store liked song IDs
  final LikedSongsService _likedSongsService = LikedSongsService(); // Create an instance

  // List to hold playlists (simple implementation, can be improved)
  List<String> playlists = [];

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _isMounted = true;
    _isPlaying = true;
    _currentSongIndex = widget.currentIndex;
    playSong(widget.songList[_currentSongIndex]);
    listenForDeviceChanges();
    monitorAudioFocus();
    scanBluetoothDevices();
    loadLikedSongs(); // Load liked songs from storage
  }

  // Load liked songs into the set
  void loadLikedSongs() async {
    likedSongs = Set<String>.from(await _likedSongsService.getLikedSongs());
    setState(() {}); // Update UI if needed
  }

  void toggleLike(String songId) async {
    setState(() {
      if (likedSongs.contains(songId)) {
        likedSongs.remove(songId); // Unlike the song
        _likedSongsService.removeLikedSong(songId); // Remove from storage
      } else {
        likedSongs.add(songId); // Like the song
        _likedSongsService.saveLikedSong(songId); // Save to storage
      }
    });
  }

  @override
  void dispose() {
    flutterBlue.stopScan();
    _isMounted = false;
    super.dispose();
  }

  void listenForDeviceChanges() {
    widget.audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.ready && _isMounted) {
        setState(() {
          _songDuration = widget.audioPlayer.duration ?? Duration.zero; // Ensure the duration is updated
        });
        print('Audio is ready');
      }

      if (state.processingState == ProcessingState.completed && _isMounted) {
        _nextSong();
      }
    });
  }

  void monitorAudioFocus() {
    widget.audioPlayer.playerStateStream.listen((event) {
      if (event.processingState == ProcessingState.idle && _isMounted) {
        setState(() {
          _isPlaying = false;
        });
        print("Device disconnected. Stopping playback.");
      }
    });
  }

  void scanBluetoothDevices() async {
    try {
      await flutterBlue.startScan(timeout: const Duration(seconds: 4));
      flutterBlue.scanResults.listen((results) {
        for (ScanResult r in results) {
          print('Found device: ${r.device.name}');
        }
      });
    } catch (e) {
      print("Error scanning for Bluetooth devices: $e");
    }
  }

  Future<void> requestPermissions() async {
    var status = await Permission.storage.status;

    if (!status.isGranted) {
      await Permission.storage.request();
    }
    await [
      Permission.bluetooth,
      Permission.location,
    ].request();
  }
  void AddtoPlaylist() async {
    var userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      showToast(message: "User not logged in!");
      return;
    }

    try {
      // Fetch the playlists that belong to the logged-in user
      var playlistsSnapshot = await FirebaseFirestore.instance
          .collection('playlists') // Directly query the playlists collection
          .where('userId', isEqualTo: userId) // Filter by userId
          .get();

      // Show dialog for the user to either create a new playlist or select an existing one
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Add to Playlist"),
            content: playlistsSnapshot.docs.isEmpty
                ? const Text("You have no playlists. Create one below.")
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...playlistsSnapshot.docs.map((playlist) {
                  return ListTile(
                    title: Text(playlist['name']),
                    onTap: () async {
                      // Add the song to the selected playlist
                      await addToExistingPlaylist(playlist.id, userId);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _createNewPlaylist(userId);
                  },
                  child: const Text("Create New Playlist"),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      showToast(message: "Error loading playlists: $e");
    }
  }

  Future<void> addToExistingPlaylist(String playlistId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('playlists')
          .doc(playlistId)
          .update({
        'songs': FieldValue.arrayUnion([widget.songModel.id])
      });

      showToast(message: "Song added to playlist!");
    } catch (e) {
      showToast(message: "Error adding song to playlist: $e");
    }
  }

  void _createNewPlaylist(String userId) async {
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
          'songs': [widget.songModel.id], // Add the current song
        });

        showToast(message: "New playlist '$playlistName' created and song added!");
      } catch (e) {
        showToast(message: "Error creating playlist: $e");
      }
    }
  }


  void showPlaylist() async {
    // Fetch the playlists for the logged-in user from Firebase
    var userId = FirebaseAuth.instance.currentUser!.uid;
    var playlists = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .get();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Current Playlists"),
          content: playlists.docs.isEmpty
              ? const Text("No playlists available.")
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: playlists.docs.map((playlist) {
              return ListTile(
                title: Text(playlist['name']),
                onTap: () {
                  // Handle playlist selection if needed
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  void playSong(FirestoreSongModel songModel) async {
    try {
      // Load the audio source first
      await widget.audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(songModel.url),
          tag: MediaItem(
            id: songModel.id,
            album: songModel.album,
            title: songModel.title,
            artUri: Uri.parse(
              'https://static.vecteezy.com/system/resources/previews/029/650/250/large_2x/music-graffiti-wallpaper-graffiti-background-music-graffiti-pattern-music-graffiti-background-music-graffiti-art-music-graffiti-paint-ai-generative-photo.jpg',
            ),
          ),
        ),
      );
      widget.audioPlayer.play(); // Start playing right after loading the audio
      context.read<SongModelProvider>().setCurrentSong(songModel);
      // Listen for when the player is ready
      widget.audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.ready && _isMounted) {
          setState(() {
            _isPlaying = true;
            _songDuration = widget.audioPlayer.duration ?? Duration.zero;
          });
        }
      });

      // Update the current position as the song plays
      widget.audioPlayer.positionStream.listen((position) {
        if (_isMounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });

      // Listen to the duration stream for updating the slider
      widget.audioPlayer.durationStream.listen((duration) {
        if (_isMounted) {
          setState(() {
            _songDuration = duration ?? Duration.zero;
          });
        }
      });

      context.read<SongModelProvider>().setId(songModel.id);

    } catch (e) {
      log("Cannot play the song: $e");
    }
  }

  void _nextSong() {
    if (_currentSongIndex < widget.songList.length - 1) {
      _currentSongIndex++;
      playSong(widget.songList[_currentSongIndex]);
      context.read<SongModelProvider>().setId(widget.songList[_currentSongIndex].id); // Set the new song ID
      context.read<SongModelProvider>().setCurrentSong(widget.songList[_currentSongIndex]); // Set the new song
    } else {
      log("No more songs to play.");
    }
  }

  void _previousSong() {
    if (_currentSongIndex > 0) {
      _currentSongIndex--;
      playSong(widget.songList[_currentSongIndex]);
      context.read<SongModelProvider>().setId(widget.songList[_currentSongIndex].id); // Set the new song ID
      context.read<SongModelProvider>().setCurrentSong(widget.songList[_currentSongIndex]); // Set the new song
    } else {
      log("No previous songs to play.");
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
  void playPauseToggle() async {
    if (_isPlaying) {
      // Pause the audio
      await widget.audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      // Play the audio
      await widget.audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001A2D),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                const SizedBox(height: 40.0),
                Column(
                  children: [
                    // Stack to overlay the liked icon on the artwork
                    Stack(
                      alignment: Alignment.topRight, // Aligns the icon to the top right
                      children: [
                        ArtWorkWidget(song: widget.songList[_currentSongIndex]),
                      ],
                    ),
                    const SizedBox(height: 50.0),
                    Text(
                      widget.songList[_currentSongIndex].title,
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      widget.songList[_currentSongIndex].artist,
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                      ),
                    ),
                    const SizedBox(height: 40.0),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: IconButton(
                    //         onPressed: showPlaylist,
                    //         icon: const Icon(
                    //           Icons.playlist_play_rounded,
                    //           color: Colors.white,
                    //           size: 40,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    Row(
                      children: [
                        Text(
                          formatDuration(_currentPosition),
                          style: const TextStyle(color: Colors.white),
                        ),
                        Expanded(
                          child: Slider(
                            value: _currentPosition.inSeconds.toDouble(),
                            min: 0.0,
                            max: _songDuration.inSeconds.toDouble(),
                            onChanged: (value) async {
                              setState(() {
                                _currentPosition = Duration(seconds: value.toInt());
                              });
                              await widget.audioPlayer.seek(_currentPosition);
                              if (!_isPlaying) {
                                widget.audioPlayer.play();
                              }
                            },
                            activeColor: Colors.green,
                            inactiveColor: Colors.white,
                          ),
                        ),
                        Text(
                          formatDuration(_songDuration),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed:  AddtoPlaylist,
                          icon: const Icon(
                            Icons.playlist_add,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        IconButton(
                          onPressed: _previousSong,
                          icon: const Icon(
                            Icons.skip_previous,
                            color: Colors.white,
                            size: 40.0,
                          ),
                        ),
                        IconButton(
                          onPressed: playPauseToggle,
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 40.0,
                          ),
                        ),
                        IconButton(
                          onPressed: _nextSong,
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                            size: 40.0,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            likedSongs.contains(widget.songList[_currentSongIndex].id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: likedSongs.contains(widget.songList[_currentSongIndex].id)
                                ? Colors.green // Set color to green if liked
                                : Colors.white, // Default color if not liked
                          ),
                          onPressed: () {
                            toggleLike(widget.songList[_currentSongIndex].id); // Toggle like
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
