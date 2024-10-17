import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/PlaylistModel.dart';

class PlaylistService {
  final CollectionReference playlistCollection =
  FirebaseFirestore.instance.collection('playlists');

  String getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<void> createPlaylist(String name, String description) async {
    String userId = getCurrentUserId();
    if (userId.isNotEmpty) {
      final newPlaylist = PlaylistModel(
        id: playlistCollection.doc().id,
        userId: userId, // Associate the playlist with the current user
        name: name,
        description: description,
        songIds: [],
      );
      await playlistCollection.doc(newPlaylist.id).set(newPlaylist.toJson());
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    await playlistCollection.doc(playlistId).delete();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    DocumentSnapshot playlistSnapshot = await playlistCollection.doc(playlistId).get();
    List<String> songIds = List<String>.from(playlistSnapshot['songIds']);

    if (!songIds.contains(songId)) {
      songIds.add(songId);
      await playlistCollection.doc(playlistId).update({'songIds': songIds});
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      DocumentSnapshot playlistSnapshot = await playlistCollection.doc(playlistId).get();

      if (playlistSnapshot.exists) {
        List<String> songIds = List<String>.from(playlistSnapshot['songIds'] ?? []);

        if (songIds.isNotEmpty && songIds.contains(songId)) {
          songIds.remove(songId);

          // Update Firestore with the new song list
          await playlistCollection.doc(playlistId).update({'songIds': songIds});

          print("Song removed from playlist successfully!");
        } else {
          print("Song ID $songId not found in the playlist");
        }
      } else {
        print("Playlist not found in Firestore.");
      }
    } catch (e) {
      print("Error removing song from playlist: $e");
    }
  }

  // Retrieve playlists only for the authenticated user
  Stream<List<PlaylistModel>> getUserPlaylists() {
    String userId = getCurrentUserId();
    if (userId.isEmpty) {
      return Stream.empty(); // No playlists if user is not authenticated
    }
    return playlistCollection
        .where('userId', isEqualTo: userId) // Filter by userId
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PlaylistModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
