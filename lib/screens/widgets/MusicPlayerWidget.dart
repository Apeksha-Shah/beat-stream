import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../controller/MusicPlayerControls.dart';
import '../../global/audio_player_singleton.dart';
class MusicPlayerWidget extends StatelessWidget {
  final SongModel currentSong;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Duration songPosition;
  final Duration songDuration;

  const MusicPlayerWidget({
    Key? key,
    required this.currentSong,
    required this.onNext,
    required this.onPrevious,
    required this.songPosition,
    required this.songDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF001A2D),
      child: Row(
        children: [
          // Album Art
          QueryArtworkWidget(
            id: currentSong.id,
            type: ArtworkType.AUDIO,
            nullArtworkWidget: const CircleAvatar(
              radius: 30,
              child: Icon(Icons.music_note, size: 30),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSong.displayNameWOExt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentSong.artist ?? "Unknown Artist",
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            children: [
              // Add the position and duration information
              Text(
                '${songPosition.inMinutes}:${songPosition.inSeconds.remainder(60).toString().padLeft(2, '0')} / '
                    '${songDuration.inMinutes}:${songDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white),
              ),
              MusicPlayerControls(
                isPlaying: audioPlayer.playing,
                currentPosition: songPosition,
                songDuration: songDuration,
                onPlayPause: () {
                  if (audioPlayer.playing) {
                    audioPlayer.pause();
                  } else {
                    audioPlayer.play();
                  }
                },
                onSkipNext: onNext, // Call the next function
                onSkipPrevious: onPrevious, // Call the previous function
                onSliderChanged: (value) {
                  audioPlayer.seek(Duration(seconds: value.toInt()));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
