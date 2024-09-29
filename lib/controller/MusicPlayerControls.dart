import 'package:flutter/material.dart';

class MusicPlayerControls extends StatefulWidget {
  final bool isPlaying;
  final Duration currentPosition;
  final Duration songDuration;
  final void Function()? onPlayPause;
  final void Function()? onSkipNext;
  final void Function()? onSkipPrevious;
  final ValueChanged<double> onSliderChanged;

  const MusicPlayerControls({
    super.key,
    required this.isPlaying,
    required this.currentPosition,
    required this.songDuration,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onSliderChanged,
  });

  @override
  State<MusicPlayerControls> createState() => _MusicPlayerControlsState();
}

class _MusicPlayerControlsState extends State<MusicPlayerControls> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [

        IconButton(
          onPressed: widget.onSkipPrevious,
          icon: const Icon(
              Icons.skip_previous,
              size: 40,
              color: Colors.white),
        ),
        const SizedBox(width: 20),
        IconButton(
          onPressed: widget.onPlayPause,
          icon: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow, size: 40, color: Colors.white),
        ),
        const SizedBox(width: 20),
        IconButton(
          onPressed: widget.onSkipNext,
          icon: const Icon(Icons.skip_next,
              size: 40,
              color: Colors.white),
        ),
      ],
    );
  }
}
