import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePlaylistPage extends StatefulWidget {
  @override
  _CreatePlaylistPageState createState() => _CreatePlaylistPageState();
}

class _CreatePlaylistPageState extends State<CreatePlaylistPage> {
  final TextEditingController _playlistNameController = TextEditingController();
  List<String> _selectedSongs = []; // Hold the list of selected song IDs

  void _createPlaylist() async {
    String playlistName = _playlistNameController.text;
    if (playlistName.isNotEmpty && _selectedSongs.isNotEmpty) {
      // Create a new playlist in Firestore
      await FirebaseFirestore.instance.collection('playlists').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'name': playlistName,
        'songIds': _selectedSongs,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context); // Return to the previous page after creation
    }
  }

  // You can fetch and display a list of songs here for selection
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Playlist"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _playlistNameController,
              decoration: InputDecoration(labelText: "Playlist Name"),
            ),
            Expanded(
              // TODO: Replace with a list of songs fetched from Firestore or the local device
              child: ListView.builder(
                itemCount: 10, // Replace with the actual number of songs
                itemBuilder: (context, index) {
                  String songId = 'song_$index'; // Example song ID
                  return CheckboxListTile(
                    title: Text("Song $index"), // Replace with actual song names
                    value: _selectedSongs.contains(songId),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedSongs.add(songId);
                        } else {
                          _selectedSongs.remove(songId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _createPlaylist,
              child: Text("Create Playlist"),
            ),
          ],
        ),
      ),
    );
  }
}
