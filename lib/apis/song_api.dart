import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<String> getAccessToken() async {
    var clientId = 'bc66efb4cc144388849e2036b46271c2';
    var clientSecret = '668088b64c9b4298a0a5b3b9c9774850';
    var credentials = '$clientId:$clientSecret';
    var base64Credentials = base64Encode(utf8.encode(credentials));

    var response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic $base64Credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['access_token'];
    } else {
      throw Exception('Failed to get token: ${response.body}');
    }
  }

  static Future<List<dynamic>> searchSongs(String accessToken, String query) async {
    var encodedQuery = Uri.encodeComponent(query);
    var response = await http.get(
      Uri.parse('https://api.spotify.com/v1/search?type=track&q=$encodedQuery'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['tracks']['items'];
    } else {
      throw Exception('Failed to fetch songs: ${response.body}');
    }
  }
}
