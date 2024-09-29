import 'package:flutter/material.dart';
import 'package:beat_stream/apis/song_api.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';


class Search extends StatefulWidget {
  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<dynamic> _songs = [];
  String _searchQuery = '';
  String _accessToken = '';

  String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) {
    if (length <= 0) return '';
    return String.fromCharCode(_chars.codeUnitAt(_rnd.nextInt(_chars.length)));
  }

  @override
  void initState() {
    super.initState();
    _searchQuery = getRandomString(1);
    generateToken();
  }

  Future<void> generateToken() async {
    try {
      _accessToken = await ApiService.getAccessToken();
      if (_searchQuery.isNotEmpty) {
        await fetchSongs(_searchQuery);
      }
    } catch (err) {
      print('Error occurred: $err');
    }
  }

  Future<void> fetchSongs(String query) async {
    try {
      var songs = await ApiService.searchSongs(_accessToken, query);
      setState(() {
        _songs = songs;
      });
    } catch (err) {
      print('Error occurred: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF001A2D),
      appBar: AppBar(
        backgroundColor: Color(0xFF001A2D),
        title: Text(
          'Search',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search song or artist',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                ),
                filled: true,
                fillColor: Color(0xFF002B40),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 18.0),
              ),
              style: TextStyle(
                color: Colors.white,
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                if (query.isNotEmpty) {
                  generateToken();
                }
              },
            ),
            SizedBox(height: 12.0),
            Expanded(
              child: _songs.isEmpty
                  ? Center(
                child: Text(
                  'No results found.',
                  style: TextStyle(color: Colors.white),
                ),
              )
                  : ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  var song = _songs[index];
                  var songName = song['name'];
                  var artistName = song['artists'][0]['name'];
                  var albumName = song['album']['name'];
                  var albumArtUrl = song['album']['images'][0]['url'];
                  var previewUrl = song['preview_url'];

                  // Print the preview URL for debugging
                  print('Preview URL: $previewUrl');

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    color: Color(0xFF002B40),
                    child: ListTile(
                      leading: Image.network(
                        albumArtUrl,
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.error, color: Colors.white);
                        },
                      ),
                      title: Text(
                        songName,
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '$artistName - $albumName',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.play_arrow, color: Colors.white),
                        onPressed: () async {
                          if (previewUrl != null && previewUrl.isNotEmpty) {
                            try {
                              bool launched = await launch(previewUrl, forceSafariVC: false,
                                  forceWebView: false);
                              if (!launched) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not open the preview URL')),
                                );
                              }
                            } catch (error) {
                              print('Error launching URL: $error');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error opening the preview URL')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Preview URL not available')),
                            );
                          }
                        },
                      ),

                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF001A2D),
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () {
                  // Navigate to home screen
                  Navigator.pushNamed(context, '/');
                },
                icon: Icon(
                  Icons.home,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.search,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}