import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSongModel {
  final String id;
  final String url;
  final String title;
  final String artist;
  final String album;
  final String genre; // Add genre
  final DateTime releaseDate; // Add release date

  FirestoreSongModel({
    required this.id,
    required this.url,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.releaseDate,
  });

  // Method to create an instance from Firestore document

  factory FirestoreSongModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Ensure data is in Map format
    return FirestoreSongModel(
      id: doc.id,
      url: data?['Url'] ?? 'default_url.mp3', // Default value or empty string
      title: data?['songName'] ?? 'Unknown Title',
      artist: data?['artist'] ?? 'Unknown Artist',
      album: data?['album'] ?? 'Unknown Album',
      genre: data?['genre'] ?? 'Unknown Genre',
      releaseDate: data?['releaseDate'] != null
          ? (data?['releaseDate'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

}
