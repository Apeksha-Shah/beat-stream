
class PlaylistModel {
  String id;
  String userId; // User ID to associate the playlist with a Firebase user
  String name;
  String description;
  List<dynamic> songIds;

  PlaylistModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.songIds,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'songIds': songIds,
    };
  }

  // Convert from Firestore JSON
  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      description: json['description'],
      songIds: List<String>.from(json['songIds']),
    );
  }
}
