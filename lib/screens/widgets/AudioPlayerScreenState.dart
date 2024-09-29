import 'dart:developer';
import 'package:beat_stream/global/toast.dart';
import 'package:beat_stream/screens/widgets/ArtWorkWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:beat_stream/global/audio_player_singleton.dart';
import 'package:provider/provider.dart';
import '../../controller/MusicPlayerControls.dart';
import '../../provider/song_model_provider.dart';

class Audioplayerscreenstate extends StatefulWidget {
  const Audioplayerscreenstate({
    super.key,
    required this.songModel,
    required this.audioPlayer,
    required this.songList,
    required this.currentIndex,
  });

  final SongModel songModel;
  final AudioPlayer audioPlayer;
  final List<SongModel> songList;
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

  // Track if the widget is mounted before calling setState
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _isMounted = true;
    _currentSongIndex = widget.currentIndex;
    playSong(widget.songList[_currentSongIndex]);
    listenForDeviceChanges(); // Start listening for device changes
    monitorAudioFocus(); // Monitor headphone/Bluetooth events
    scanBluetoothDevices(); // Scan for Bluetooth devices
  }

  @override
  void dispose() {
    flutterBlue.stopScan(); // Stop Bluetooth scanning when screen is disposed
    _isMounted = false;
    super.dispose();
  }

  void listenForDeviceChanges() {
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.ready && _isMounted) {
        print('Audio is ready');
      }

      if (state.processingState == ProcessingState.completed && _isMounted) {
        // When the song is completed, play the next song
        _nextSong();
      }
    });
  }

  void listenForBluetoothState() {
    flutterBlue.state.listen((state) {
      if (state == BluetoothState.off) {
        // Handle when Bluetooth is turned off
        if (_isMounted) {
          setState(() {
            _isPlaying = false;
          });
          audioPlayer.pause();
          showToast(message: 'Bluetooth disconnected.');
        }
      }
    });
  }

  // Detect if headphones are connected or Bluetooth controls
  void monitorAudioFocus() {
    audioPlayer.playerStateStream.listen((event) {
      // Check if the device was unmounted (e.g., headphones or Bluetooth disconnected)
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

    if (!status.isDenied) {
      bool isOpened = await openAppSettings();
      if (!isOpened) {
        print('Failed to open app settings');
      }
    } else if (!status.isGranted) {
      await Permission.storage.request();
    }
    await [
      Permission.bluetooth,
      Permission.location, // Required for scanning
    ].request();
  }

  void playSong(SongModel songModel) async {
    try {
      await audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(songModel.uri!),
          tag: MediaItem(
            id: '${widget.songModel.id}',
            album: '${widget.songModel.album}',
            title: '${widget.songModel.title}',
            artUri: Uri.parse(
                'https://static.vecteezy.com/system/resources/previews/029/650/250/large_2x/music-graffiti-wallpaper-graffiti-background-music-graffiti-pattern-music-graffiti-background-music-graffiti-art-music-graffiti-paint-ai-generative-photo.jpg'),
          ),
        ),
      );
      context.read<SongModelProvider>().setId(songModel.id);
      audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });

      widget.audioPlayer.positionStream.listen((position) {
        if (_isMounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });
      audioPlayer.positionStream.listen((position) {
        if (_isMounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });
      widget.audioPlayer.durationStream.listen((duration) {
        if (_isMounted) {
          setState(() {
            _songDuration = duration ?? Duration.zero;
          });
        }
      });
      audioPlayer.durationStream.listen((duration) {
        if (_isMounted) {
          setState(() {
            _songDuration = duration ?? Duration.zero;
          });
        }
      });
    } on Exception {
      log("Cannot find the song");
    }
  }

  void _skipForward() {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    if (newPosition < _songDuration) {
      widget.audioPlayer.seek(newPosition);
    }
  }

  void _skipBackward() {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    if (newPosition >= Duration.zero) {
      widget.audioPlayer.seek(newPosition);
    } else {
      widget.audioPlayer.seek(Duration.zero);
    }
  }

  void _nextSong() {
    if (_currentSongIndex < widget.songList.length - 1) {
      _currentSongIndex++;
      playSong(widget.songList[_currentSongIndex]);
    } else {
      log("No more songs to play.");
    }
  }

  void _previousSong() {
    if (_currentSongIndex > 0) {
      _currentSongIndex--;
      playSong(widget.songList[_currentSongIndex]);
    } else {
      log("This is the first song.");
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
                const SizedBox(height: 40.0), // Reduced from 70 to 40
                Column(
                  children: [
                    const ArtWorkWidget(),
                    const SizedBox(height: 50.0), // Reduced from 100 to 50
                    Text(
                      widget.songList[_currentSongIndex].displayNameWOExt,
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      widget.songList[_currentSongIndex].artist ?? "Unknown Artist",
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                      ),
                    ),
                    const SizedBox(height: 30.0), // Reduced spacing here
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
                            onChanged: (value) {
                              setState(() {
                                widget.audioPlayer.seek(Duration(seconds: value.toInt()));
                                audioPlayer.seek(Duration(seconds: value.toInt()));
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
                    const SizedBox(height: 20.0), // Reduced spacing between slider and buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _skipBackward,
                          icon: const Icon(Icons.replay_10, color: Colors.white, size: 40),
                        ),
                        IconButton(
                          onPressed: _previousSong,
                          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                        ),
                        CircleAvatar(
                          radius: 30.0,
                          backgroundColor: Colors.green,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                if (_isPlaying) {
                                  widget.audioPlayer.pause();
                                  audioPlayer.pause();
                                } else {
                                  widget.audioPlayer.play();
                                  audioPlayer.play();
                                }
                                _isPlaying = !_isPlaying;
                              });
                            },
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 40.0,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _nextSong,
                          icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                        ),
                        IconButton(
                          onPressed: _skipForward,
                          icon: const Icon(Icons.forward_10, color: Colors.white, size: 40),
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
