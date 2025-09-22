import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../track_state.dart'; // <-- добавлено

class ProfileScreen extends StatefulWidget {
  final List<Track> allTracks;

  const ProfileScreen({super.key, required this.allTracks});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Track> likedTracks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLikedTracks();
  }

  Future<void> _loadLikedTracks() async {
    setState(() => loading = true);
    final sp = await SharedPreferences.getInstance();
    final likes = widget.allTracks
        .where((t) => sp.getBool('liked_${t.title}') ?? false)
        .toList();
    setState(() {
      likedTracks = likes;
      loading = false;
    });
  }

  Future<void> _toggleLike(Track track) async {
    final sp = await SharedPreferences.getInstance();
    final key = 'liked_${track.title}';
    final now = sp.getBool(key) ?? false;
    await sp.setBool(key, !now);

    setState(() {
      if (!now) {
        likedTracks.add(track);
      } else {
        likedTracks.removeWhere((t) => t.title == track.title);
      }
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 100, left: 24, right: 16, bottom: 24),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            color: Colors.white,
            child: const Icon(Icons.favorite, color: Colors.black, size: 50),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Понравившиеся треки',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('${likedTracks.length} лайков', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: TrackState.dominantColor,
      builder: (context, dominant, _) {
        final gradientTop = HSLColor.fromColor(dominant)
            .withLightness((HSLColor.fromColor(dominant).lightness + 0.15).clamp(0.0, 1.0))
            .toColor();

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [gradientTop, Colors.black],
                stops: const [0.0, 0.8],
              ),
            ),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadLikedTracks,
              child: likedTracks.isEmpty
                  ? ListView(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 80),
                  const Center(
                    child: Text(
                      'Нет лайкнутых треков',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              )
                  : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: likedTracks.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) return _buildHeader();
                  final track = likedTracks[index - 1];

                  return Container(
                    height: 64,
                    padding: const EdgeInsets.only(left: 24, right: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                offset: Offset(0, 0),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              track.coverAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white12,
                                child: const Icon(Icons.music_note, color: Colors.white30),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              Transform.translate(
                                offset: const Offset(5, -12),
                                child: Text(
                                  track.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(5, 18),
                                child: Text(
                                  track.artist,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _toggleLike(track),
                          icon: const Icon(Icons.favorite, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
