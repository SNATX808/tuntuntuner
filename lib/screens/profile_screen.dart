import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  final List<Track> allTracks;

  const ProfileScreen({super.key, required this.allTracks});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Track> likedTracks = [];

  @override
  void initState() {
    super.initState();
    _loadLikedTracks();
  }

  Future<void> _loadLikedTracks() async {
    final sp = await SharedPreferences.getInstance();
    final likes = widget.allTracks.where((t) =>
    sp.getBool('liked_${t.title}') ?? false).toList();
    setState(() => likedTracks = likes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        title: const Text('Профиль', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey,
              Colors.black,
            ],
          ),
        ),
        child: likedTracks.isEmpty
            ? const Center(
          child: Text(
            'Нет лайкнутых треков',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        )
            : ListView.builder(
          itemCount: likedTracks.length,
          itemBuilder: (context, index) {
            final track = likedTracks[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(track.coverAsset,
                    width: 50, height: 50, fit: BoxFit.cover),
              ),
              title: Text(track.title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(track.artist,
                  style: const TextStyle(color: Colors.white70)),
            );
          },
        ),
      ),
    );
  }
}