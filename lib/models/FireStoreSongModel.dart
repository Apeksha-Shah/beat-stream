import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSongModel {
  final String id;
  final String url;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final DateTime releaseDate;
  final String ImageUrl;
  final String lyrics;

  FirestoreSongModel({
    required this.id,
    required this.url,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.releaseDate,
    required this.ImageUrl,
    required this.lyrics,
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
      ImageUrl: data?['ImageUrl'] ?? 'https://via.placeholder.com/150',
      lyrics: data?['lyrics'] ?? 'Unknown lyrics',
    );
  }
  factory FirestoreSongModel.fromMap(Map<String, dynamic> map) {
    return FirestoreSongModel(
      id: map['id'] ?? '',
      url: map['Url'] ?? '',
      title: map['songName'] ?? 'Unknown Title',
      artist: map['artist'] ?? 'Unknown Artist',
      album: map['album'] ?? 'Unknown Album',
      genre: map['genre'] ?? 'Unknown Genre',
      releaseDate: (map['releaseDate'] != null)
          ? (map['releaseDate'] as Timestamp).toDate()
          : DateTime.now(),
      ImageUrl: map['ImageUrl'] ?? 'https://example.com/default_image.png',
      lyrics: map['lyrics'] ?? '',
    );
  }
  // Method to serialize the FirestoreSongModel to a Map for storing in Firestore or JSON
  Map<String, dynamic> toJson() {
    return {
      'Url': url,
      'songName': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'releaseDate': releaseDate.toIso8601String(), // Convert DateTime to string
      'ImageUrl': ImageUrl,
      'lyrics': lyrics,
    };
  }
}
