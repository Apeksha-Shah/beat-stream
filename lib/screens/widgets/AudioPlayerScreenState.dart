import 'dart:developer';
import 'package:beat_stream/global/toast.dart';
import 'package:beat_stream/screens/widgets/ArtWorkWidget.dart';
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

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _isMounted = true;
    _currentSongIndex = widget.currentIndex;
    playSong(widget.songList[_currentSongIndex]);
    listenForDeviceChanges();
    monitorAudioFocus();
    scanBluetoothDevices();
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
        }// Listen for current position changes
        widget.audioPlayer.positionStream.listen((position) {
          if (_isMounted) {
            setState(() {
              _currentPosition = position; // Ensure _currentPosition is always updated
            });
          }
        });

// Listen for duration changes
        widget.audioPlayer.durationStream.listen((duration) {
          if (_isMounted) {
            setState(() {
              _songDuration = duration ?? Duration.zero; // Ensure _songDuration is updated
            });
          }
        });

      });

      context.read<SongModelProvider>().setId(songModel.id );

    } catch (e) {
      log("Cannot play the song: $e");
    }
  }

  void _nextSong() {
    if (_currentSongIndex < widget.songList.length - 1) {
      _currentSongIndex++;
      playSong(widget.songList[_currentSongIndex]);
      context.read<SongModelProvider>().setId(widget.songList[_currentSongIndex].id ); // Set the new song ID
      context.read<SongModelProvider>().setCurrentSong(widget.songList[_currentSongIndex]);       // Set the new song
    } else {
      log("No more songs to play.");
    }
  }

  void _previousSong() {
    if (_currentSongIndex > 0) {
      _currentSongIndex--;
      playSong(widget.songList[_currentSongIndex]);
      context.read<SongModelProvider>().setId(widget.songList[_currentSongIndex].id ); // Set the new song ID
      context.read<SongModelProvider>().setCurrentSong(widget.songList[_currentSongIndex]);       // Set the new song
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
                    ArtWorkWidget(song: widget.songList[_currentSongIndex]),
                    const SizedBox(height: 50.0),
                    Text(
                      widget.songList[_currentSongIndex].title, // Updated
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      widget.songList[_currentSongIndex].artist, // Updated
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                      ),
                    ),
                    const SizedBox(height: 60.0),
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
                            max: _songDuration.inSeconds > 0 ? _songDuration.inSeconds.toDouble() : 1.0,  // Prevents max from being zero
                            onChanged: (value) {
                              setState(() {
                                widget.audioPlayer.seek(Duration(seconds: value.toInt()));
                              });
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
                    const SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _previousSong, // Handle previous song
                          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                        ),
                        IconButton(
                          onPressed: () {
                            final newPosition = _currentPosition - const Duration(seconds: 10);
                            widget.audioPlayer.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                          },
                          icon: const Icon(Icons.replay_10, color: Colors.white, size: 40),
                        ),
                        CircleAvatar(
                          radius: 30.0,
                          backgroundColor: Colors.green,
                          child: StreamBuilder<PlayerState>(
                            stream: widget.audioPlayer.playerStateStream,
                            builder: (context, snapshot) {
                              final playerState = snapshot.data;
                              final processingState = playerState?.processingState;
                              final playing = playerState?.playing;

                              if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                                return const CircularProgressIndicator(color: Colors.white);
                              } else if (playing != true) {
                                return IconButton(
                                  onPressed: widget.audioPlayer.play,
                                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                                );
                              } else if (processingState != ProcessingState.completed) {
                                return IconButton(
                                  onPressed: widget.audioPlayer.pause,
                                  icon: const Icon(Icons.pause, color: Colors.white, size: 30),
                                );
                              } else {
                                return IconButton(
                                  onPressed: () {
                                    _nextSong(); // Skip to next song when done
                                  },
                                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                                );
                              }
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final newPosition = _currentPosition + const Duration(seconds: 10);
                            widget.audioPlayer.seek(newPosition > _songDuration ? _songDuration : newPosition);
                          },
                          icon: const Icon(Icons.forward_10, color: Colors.white, size: 40),
                        ),
                        IconButton(
                          onPressed: _nextSong, // Handle next song
                          icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
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