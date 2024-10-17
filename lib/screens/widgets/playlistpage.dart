import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../global/audio_player_singleton.dart';
import '../../models/FireStoreSongModel.dart';
import '../../provider/song_model_provider.dart';
import 'PlaylistDetailScreen.dart';
import 'MusicPlayerWidget.dart';

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<QueryDocumentSnapshot>? playlists; // Local list of playlists
  Future<void> _fetchPlaylistSongs(String playlistId, SongModelProvider songProvider) async {
    var playlistSnapshot = await FirebaseFirestore.instance
        .collection('songs')
        .where('playlistId', isEqualTo: playlistId)
        .get();

    List<Map<String, dynamic>> playlistSongs = playlistSnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'Url': doc['Url'],
        'songName': doc['songName'],
        'artist': doc['artist'],
        'album': doc['album'],
        'genre': doc['genre'],
        'ImageUrl': doc['ImageUrl'],
        'lyrics': doc['lyrics'],
      };
    }).toList();

    songProvider.loadPlaylist(playlistSongs);  // Load the songs into the provider
  }

  // Fetches the playlists from Firestore
  Future<void> _fetchPlaylists(String userId) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('playlists')
        .where('userId', isEqualTo: userId)
        .get();

    setState(() {
      playlists = snapshot.docs; // Store the fetched playlists locally
    });
  }

  // Function to delete a playlist and update the local list
  Future<void> _deletePlaylist(String playlistId) async {
    try {
      await FirebaseFirestore.instance.collection('playlists').doc(playlistId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Playlist deleted successfully!")),
      );

      // Update the local list by removing the deleted playlist
      setState(() {
        playlists?.removeWhere((playlist) => playlist.id == playlistId);
      });
    } catch (e) {
      print("Error deleting playlist: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting playlist")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    var userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _fetchPlaylists(userId); // Fetch playlists when the page loads
    }
  }
// Show confirmation dialog before deleting
  Future<void> _showDeleteConfirmationDialog(String playlistId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Playlist'),
          content: Text('Are you sure you want to delete this playlist?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _deletePlaylist(playlistId);  // Call the delete method
                Navigator.of(context).pop();  // Close the dialog after deletion
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SongModelProvider>(
      builder: (context, songProvider, child) {
        var userId = FirebaseAuth.instance.currentUser?.uid;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF001A2D),
            title: const Text(
              "My Playlists",
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: const Color(0xFF001A2D),
          body: userId == null
              ? Center(child: Text("User not logged in!"))
              : playlists == null
              ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching
              : playlists!.isEmpty
              ? const Center(child: Text("No playlists found."))
              : ListView.builder(
            itemCount: playlists!.length,
            itemBuilder: (context, index) {
              var playlist = playlists![index];

              return ListTile(
                leading: const Icon(
                  Icons.playlist_play,
                  color: Colors.white,
                  size: 35.0,
                ),
                title: Text(
                  playlist['name'],
                  style: const TextStyle(color: Colors.white, fontSize: 20.0),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmationDialog(playlist.id); // Show confirmation dialog
                      },
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ],
                ),
                onTap: () {
                  // Fetch playlist songs when playlist is tapped
                  _fetchPlaylistSongs(playlist.id, songProvider);
                  // Navigate to the selected playlist's song list
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaylistDetailScreen(
                        playlistId: playlist.id,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          bottomNavigationBar: buildNavigationButtons(),
          // Custom bottom widget showing current playing song (if any)
          bottomSheet: SafeArea(
            child: SizedBox(
              height: 130,
              child: BottomAppBar(
                color: const Color(0xFF001A2D),
                child: songProvider.hasCurrentSong() && audioPlayer.playing
                    ? StreamBuilder<Duration?>(
                  stream: audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final songDuration = audioPlayer.duration ?? Duration.zero;
                    final currentSong = songProvider.getCurrentSong();
                    return MusicPlayerWidget(
                      currentSong: currentSong ??
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
                      onNext: () async {
                        await songProvider.nextSong();
                      },
                      onPrevious: () async {
                        await songProvider.previousSong();
                      },
                      songPosition: position,
                      songDuration: songDuration,
                    );
                  },
                )
                    : const SizedBox.shrink(), // Return an empty widget if no song is playing
              ),

            ),
          ),
        );
      },
    );
  }
  Widget buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: IconButton(
            onPressed: () {
                Navigator.pushNamed(context, '/');
            },
            icon: const Icon(Icons.home, size: 30, color: Colors.white),
          ),
        ),
        Expanded(
          child: IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
            icon: const Icon(Icons.search, size: 30, color: Colors.white),
          ),
        ),
        Expanded(
          child: IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/liked_songs'); // Navigate to liked songs screen
            },
            icon: const Icon(Icons.favorite_border, size: 30, color: Colors.white), // Liked songs icon
          ),
        ),
        Expanded(
          child: IconButton(
            icon: const Icon(
                Icons.library_music,
                size: 30, color: Colors.white
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlaylistPage()),
              );
            },
          ),
        ),
      ],
    );
  }
}
