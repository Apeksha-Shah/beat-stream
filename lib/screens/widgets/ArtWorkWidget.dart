import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../provider/song_model_provider.dart';

class ArtWorkWidget extends StatelessWidget {
  const ArtWorkWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return QueryArtworkWidget(
      id: context.watch<SongModelProvider>().id,
      type: ArtworkType.AUDIO,
      artworkWidth: 300,
      artworkHeight: 300,
      artworkFit: BoxFit.cover,
      nullArtworkWidget: const Icon(
        Icons.music_note,
        size: 300,
      ),
    );
  }
}
