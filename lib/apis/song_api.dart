import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';

class ApiService {
  static Future<String> getAccessToken() async {
    var credentials = '${Secrets.clientId}:${Secrets.clientSecret}';
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
